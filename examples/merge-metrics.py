import ast, glob, re, subprocess 

class MetricsAPI(object):
    '''
    Base Metrics Api implementation
    '''
    def __init__(self):
        pass

    def _append_data_to_each_line(self):
        pass

    def _get_address(self):
        ''' get SC address from the file name '''
        return [
            re.search(r"/([a-z0-9]{40})_", i).group(1)
            for i in glob.glob("./output/*/*.sol")
        ]

    def _get_firstseen_lastseen(self, address):
        with open('contracts.json', 'r') as f:
            for line in f:
                o = ast.literal_eval(line)
                if o['address'] == address:
                    return [o['firstseen'], o['lastseen']]

    def write_solidity_metrics(self):
        jar = '../target/SolMet-1.0-SNAPSHOT.jar'
        for input in glob.glob("./output/*/*.sol"):
            output = re.sub('.sol$','.out' , input)
            subprocess.call(['java', '-jar', jar, '-inputFile', input, '-outFile', output])

    def append_solidity_metrics(self, address):
        ''' It opens the metrics' output generated from SOLMET and append the lastseen and firstseen data generated from EtherChain'''
        pass


if __name__ == "__main__":
    m = MetricsAPI()
    #print(m._get_address())
    print(m._get_firstseen_lastseen('0xa6e0b24c65758154cac6f33b0c455727ab6193cb'))
