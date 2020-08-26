import torch
import torch.nn as nn
import torch.optim as optim
from torch.optim import lr_scheduler
from torchvision import models
import time
import copy
# Fine tune ResNet
class TrainPred():
    def __init__(self, device):
        self.device = device
        self.model = models.resnet18(pretrained=True)

    def train_model(self, dataloaders, dataset_sizes, num_epochs=50):
        since = time.time()
        num_ftrs = self.model.fc.in_features
        self.model.fc = nn.Linear(num_ftrs, 2)

        self.model = self.model.to(self.device)

        criterion = nn.CrossEntropyLoss()

        # Observe that all parameters are being optimized
        optimizer = optim.SGD(self.model.parameters(), lr=0.0001, momentum=0.9)

        # Decay LR by a factor of 0.1 every 7 epochs
        exp_lr_scheduler = lr_scheduler.StepLR(optimizer, step_size=7, gamma=0.1)
        best_model_wts = copy.deepcopy(self.model.state_dict())
        best_acc = 0.0

        for epoch in range(num_epochs):
            print('Epoch {}/{}'.format(epoch, num_epochs - 1))
            print('-' * 10)
            # Each epoch has a training and validation phase
            for phase in ['train', 'val']:
                if phase == 'train':
                    self.model.train()  # Set model to training mode
                else:
                    self.model.eval()   # Set model to evaluate mode
                running_loss = 0.0
                running_corrects = 0
                # Iterate over data.
                preds_val = []
                output_val = []
                for inputs, labels in dataloaders[phase]:
                    inputs = inputs.to(self.device)
                    labels = labels.to(self.device)
                    # zero the parameter gradients
                    optimizer.zero_grad()
                    # forward
                    # track history if only in train
                    with torch.set_grad_enabled(phase == 'train'):
                        outputs = self.model(inputs)
                        _, preds = torch.max(outputs, 1)
                        loss = criterion(outputs, labels)
                        # backward + optimize only if in training phase
                        if phase == 'train':
                            loss.backward()
                            optimizer.step()
                    # statistics
                    running_loss += loss.item() * inputs.size(0)
                    running_corrects += torch.sum(preds == labels.data)
                    preds_val.extend(preds)
                    output_val.extend(torch.nn.functional.softmax(outputs, dim=1))
                if phase == 'train':
                    exp_lr_scheduler.step()
                epoch_loss = running_loss / dataset_sizes[phase]
                epoch_acc = running_corrects.double() / dataset_sizes[phase]
                print('{} Loss: {:.4f} Acc: {:.4f}'.format(
                phase, epoch_loss, epoch_acc))
                # deep copy the model
                if phase == 'val' and epoch_acc > best_acc:
                    best_acc = epoch_acc
                    best_model_wts = copy.deepcopy(self.model.state_dict())
                    prediction_val = torch.stack(preds_val, dim=0)
                    prob_val = torch.stack(output_val, dim=0)
        time_elapsed = time.time() - since
        print('Training complete in {:.0f}m {:.0f}s'.format(
            time_elapsed // 60, time_elapsed % 60))
        print('Best val Acc: {:4f}'.format(best_acc))
        # load best model weights
        self.model.load_state_dict(best_model_wts)
        del dataloaders
        del inputs
        del labels
        del best_model_wts
        torch.cuda.empty_cache()
        m = torch.nn.Softmax(dim=1)
        return best_acc, prediction_val, m(prob_val)


    def Pred(self, dataloader):
        self.model.eval()
        self.model = self.model.to(self.device)
        preds_all = []
        prob_all = []
        for inputs, _ in dataloader:
            inputs = inputs.to(self.device)
            logits = self.model(inputs)
            _, preds = torch.max(logits, 1)
            preds_all.extend(preds)
            prob_all.extend(torch.nn.functional.softmax(logits, dim=1))
        prob_all = torch.stack(prob_all, dim=0)
        preds_all = torch.stack(preds_all, dim=0)
        return prob_all, preds_all
