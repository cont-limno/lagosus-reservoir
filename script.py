import os
import pickle
import torch
import numpy as np
from torchvision import transforms
from functions.DataLoading import ImageFilelist
from torch.utils.data import DataLoader
from itertools import compress
import os
import csv
from functions import Train
import random
# script for the experiment
device = torch.device("cuda:0" if torch.cuda.is_available() else "cpu")
#device = torch.device("cpu")

torch.manual_seed(1)
epoch_num = 50
rep_exp = 10
def main(final_model_path, train_dir):
    # save the results
    result_dir = final_model_path + 'withlabel/'
    if not os.path.exists(result_dir):
        os.makedirs(result_dir)
    """load data"""
    positive_dir = train_dir + "RSVR/"
    negative_dir = train_dir + "NL/"
    X_pos = [positive_dir + s for s in os.listdir(positive_dir)]
    X_neg = [negative_dir + s for s in os.listdir(negative_dir)]
    train_transformations = transforms.Compose([
        transforms.RandomHorizontalFlip(),
        transforms.ToTensor(),
        transforms.Normalize(mean=[0.485, 0.456, 0.406],
                             std=[0.229, 0.224, 0.225])])
    test_transformations = transforms.Compose([
        transforms.ToTensor(),
        transforms.Normalize(mean=[0.485, 0.456, 0.406],
                             std=[0.229, 0.224, 0.225])])
    val_acc_avg = 0.0
    # train model
    for iter in range(rep_exp):
    # remove samples from positive to make positive class and negative class balanced
        # split X_pos and X_neg into training and testing
        idx = np.arange(min(len(X_neg),len(X_pos)))
        idx_tr = idx % rep_exp != iter
        idx_te = idx % rep_exp == iter
        Xtrain_pos = list(compress(X_pos, idx_tr))
        Xtrain_neg = list(compress(X_neg, idx_tr))
        Xval_pos = list(compress(X_pos, idx_te))
        Xval_neg = list(compress(X_neg, idx_te))
        Xtrain = Xtrain_pos + Xtrain_neg
        Xval = Xval_pos + Xval_neg
        ytrain = np.concatenate([np.ones(len(Xtrain_pos), dtype=int), np.zeros(len(Xtrain_neg), dtype=int)], 0)
        yval = np.concatenate([np.ones(len(Xval_pos), dtype=int), np.zeros(len(Xval_neg), dtype=int)], 0)
        train_loader = torch.utils.data.DataLoader(ImageFilelist(Xtrain, ytrain,transform=train_transformations),
                                               batch_size=32, shuffle=True, num_workers=1, pin_memory=True)
        # reduce batch_sizes to 32, 16, 8 if there is memory issue.

        val_loader = torch.utils.data.DataLoader(ImageFilelist(Xval, yval,transform=test_transformations),
                                                  batch_size=32, shuffle=False, num_workers=1, pin_memory=True)
        dataloaders = {"train": train_loader, "val": val_loader}
        dataset_sizes = {"train": len(ytrain), "val": len(yval)}
        TrainPred = Train.TrainPred(device)
        acc, prediction_val, prob_val = TrainPred.train_model(dataloaders, dataset_sizes, num_epochs=epoch_num)

        prediction_val = prediction_val.data.cpu().numpy()
        prob_val = prob_val.data.cpu().numpy()
        val_acc_avg += acc

        #save as csv
        save_file_path = result_dir + 'iter' + str(iter) + '.csv'
        with open(save_file_path, mode='w') as csvfile:
            csv_writer = csv.writer(csvfile, delimiter=',', quotechar='"',
                                quoting=csv.QUOTE_MINIMAL)
            csv_writer.writerow(
                ["Prediction", "True Label", "Probability", "Name"])
            for i in range(len(yval)):
                csv_writer.writerow([prediction_val[i], yval[i], prob_val[i], Xval[i]])
    val_acc_avg = val_acc_avg/rep_exp
    print('Average Test Accuracy: {}'.format(val_acc_avg))
    del dataloaders
    del TrainPred
    ## retrain the model and saves model with name model.pkl
    min_len = min(len(X_pos), len(X_neg))
    X_pos_sampled = random.sample(X_pos, min_len)
    X_neg_sampled = random.sample(X_neg, min_len)
    X_samled = X_pos_sampled + X_neg_sampled
    y_sampled = np.concatenate([np.ones(len(X_pos_sampled), dtype=int),
                             np.zeros(len(X_neg_sampled), dtype=int)], 0)
    data_loader = torch.utils.data.DataLoader(
                    ImageFilelist(X_samled, y_sampled, transform=train_transformations),
                    batch_size=32, shuffle=True, num_workers=1, pin_memory=True)
    dataloaders = {"train": data_loader, "val": data_loader} # no validation, validation error is train error
    dataset_sizes = {"train": len(y_sampled), "val": len(y_sampled)}
    TrainPred = Train.TrainPred(device)
    acc, prediction_val, logits_val = TrainPred.train_model(dataloaders,
                                                            dataset_sizes,
                                                            num_epochs=epoch_num)
    with open(final_model_path + 'model.pkl' , 'wb') as output:
        pickle.dump({'model_final': TrainPred}, output, pickle.HIGHEST_PROTOCOL)
    del dataloaders
    del TrainPred
    torch.cuda.empty_cache()

## prediction
def prediction(final_model_path, pred_dir):
    """load model"""
    with open(final_model_path + 'model.pkl' , 'rb') as input:
        saved_model = pickle.load(input)
        TrainPred = saved_model['model_final']
    """create results directory"""
    result_dir = final_model_path + 'PredOn_' + pred_dir
    if not os.path.exists(result_dir):
        os.makedirs(result_dir)
    save_file_path = result_dir + 'prediction.csv'
    csvfile = open(save_file_path, mode = 'w')
    csv_writer = csv.writer(csvfile, delimiter=',', quotechar='"',
                            quoting=csv.QUOTE_MINIMAL)
    csv_writer.writerow(
                ["Prediction", "Probability", "Name"])
    """load data"""

    for folder in os.listdir(pred_dir):
        X_pred = [pred_dir + folder + '/' + s for s in os.listdir(pred_dir + folder)]
        pred_transformations = transforms.Compose([
            transforms.RandomHorizontalFlip(),
            transforms.ToTensor(),
            transforms.Normalize(mean=[0.485, 0.456, 0.406],
                                 std=[0.229, 0.224, 0.225])])
        y_fake = -1 * np.ones(len(X_pred), dtype=int)
        pred_loader = torch.utils.data.DataLoader(ImageFilelist(X_pred, y_fake, transform=pred_transformations),
                                                   batch_size=2, shuffle=False, num_workers=1, pin_memory=True)
        prob, preds = TrainPred.Pred(pred_loader)
        preds = preds.data.cpu().numpy()
        prob = prob.data.cpu().numpy()
        for i in range(len(X_pred)):
            csv_writer.writerow([preds[i], prob[i],X_pred[i]])
        del pred_loader
    csvfile.close()

if __name__ == '__main__':
    #image directories
    train_data_dir = "LAGOSNE_Train/"
    pred_data_dir = "LAGOSNE_Unclassified/"
    #save path
    final_model_path = 'results/TrainOn_' + train_data_dir
    if not os.path.isfile(final_model_path + 'model.pkl'):
        main(final_model_path, train_data_dir)
    prediction(final_model_path, pred_data_dir)

