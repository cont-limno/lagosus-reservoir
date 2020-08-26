import torch.utils.data as data
from PIL import Image
import os
import os.path


def default_loader(path):
    return Image.open(path).convert('RGB')


def default_flist_reader(filepath, label):
    """
    flist format: impath label\nimpath label\n ...(same to caffe's filelist)
    """
    imlist = []
    for n in range(len(label)):
        impath, imlabel = filepath[n], label[n]
        imlist.append((impath, int(imlabel)))
    return imlist


class ImageFilelist(data.Dataset):
    def __init__(self, filepath, label, transform=None,
                 flist_reader=default_flist_reader, loader=default_loader):
        self.imlist = flist_reader(filepath, label)
        self.transform = transform
        self.loader = loader

    def __getitem__(self, index):
        impath, target = self.imlist[index]
        img = self.loader(os.path.join(impath))
        if self.transform is not None:
            img = self.transform(img)
        return img, target

    def __len__(self):
        return len(self.imlist)