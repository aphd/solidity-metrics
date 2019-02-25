import ast, glob, os, re, subprocess 

class MergeMetrics(object):
    '''
    Base Metrics Api implementation
    '''
    def __init__(self):
        self.solmetant = 'solmetant.csv' # solidity metrics antonio file
        self.etherscan_json = self._get_contracts_json()

    def _get_contracts_json(self):
        with open('contracts.json', 'r') as f:
            return [ast.literal_eval(line) for line in f]

    def _get_file_name_from_contract_json_file(self, obj):
            src = os.path.join('./output', obj["address"].replace("0x", "")[:2].lower())
            src = "/".join([src, obj["address"].replace("0x", "")])
            return "_".join([src, obj["name"] + '.out'])
    
    def _write_file_header(self):
        ''' TODO '''
        pass

    def merge_etherscan_with_solmet(self):
        fh = open(self.solmetant, 'w')  
        for obj in self.etherscan_json:
            fn = self._get_file_name_from_contract_json_file(obj)
            lines = open(fn, 'r').readlines()
            print(";".join([lines[1].rstrip(), 'FS', 'LS']))
            fh.write(';'.join([lines[1].rstrip(), obj['firstseen'], obj['lastseen'], '\n']))
        fh.close()  

if __name__ == "__main__":
    m = MergeMetrics()
    print(m.merge_etherscan_with_solmet())
