import csv

def process_results_wlabel(in_dir,out_dir):
    for iter in range(10):
        reader = open(in_dir + 'iter' + str(iter) + '.csv', 'r', newline = '')
        writer = open(out_dir + 'iter' + str(iter) + 'processed' + '.csv', 'w' , newline ='')
        csvwriter = csv.writer(writer, delimiter = ',', quotechar = '|')
        #skip header and create new
        reader.readline()
        header = ['prediction', 'truelabel' ,'resprob', 'nlprob' , 'lagoslakeid']
        csvwriter.writerow(header)

        for line in reader:
            #split line to make list
            row = line.split(',')
            #find lagoslakeid
            lagoslakeid = int(row[3][row[3].find('lagoslakeid_')+12:row[3].find('_scale')])

            #process probabilities
            i = row[2].find(' ')
            resprob = row[2][0:i].replace('[','')
            nlprob = row[2][i:].replace(']','').replace(' ','')

            #write each row
            csvwriter.writerow([row[0], row[1], resprob, nlprob, lagoslakeid])
        reader.close()
        writer.close()


def main():
    in_dir = 'C:/Users/FWL/Dropbox/CL_RSVR/LAGOS_RSVR_2019/RSVR Identification model/Sams_Code/resultsNE/TrainOn_LAGOSNE_Train/withlabel/'
    out_dir = 'C:/Users/FWL/Desktop/NE_wlabelprocessed/'
    process_results_wlabel(in_dir,out_dir)

if __name__ == "__main__":
    main()