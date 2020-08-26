import csv

def process_results_nolabel(in_dir,out_dir):
    reader = open(in_dir + '.csv', 'r', newline = '')
    writer = open(out_dir + '.csv', 'w' , newline ='')
    csvwriter = csv.writer(writer, delimiter = ',', quotechar = '|')
    #skip header and create new
    reader.readline()
    header = ['prediction', 'resprob', 'nlprob' , 'lagoslakeid']
    csvwriter.writerow(header)

    for line in reader:
        #split line to make list
        row = line.split(',')
        #find lagoslakeid
        lagoslakeid = int(row[2][row[2].find('lagoslakeid_')+12:row[2].find('_scale')])

        #process probabilities
        i = row[1].find(' ')
        resprob = row[1][0:i].replace('[','')
        nlprob = row[1][i:].replace(']','').replace(' ','')

        #write each row
        csvwriter.writerow([row[0], resprob, nlprob, lagoslakeid])
    reader.close()
    writer.close()


def main():
    in_dir = 'C:/Users/FWL/Desktop/Test/results_test'
    out_dir = 'C:/Users/FWL/Desktop/Test/processed_results'
    process_results_nolabel(in_dir,out_dir)

if __name__ == "__main__":
    main()
