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

    def get_sol_file_name(self, obj):
            src = os.path.join('./output', obj["address"].replace("0x", "")[:2].lower())
            src = "/".join([src, obj["address"].replace("0x", "")])
            return "_".join([src, obj["name"]])
    
    def _write_file_header(self):
        self.outf = open(self.solmetant, 'w')
        self.outf.write('SolidityFile;ETHAddress;ContractName;Type;SLOC;LLOC;CLOC;NF;WMC;NL;NLE;NUMPAR;NOS;DIT;NOA;NOD;CBO;NA;NOI;Avg. McCC;Avg. NL;Avg. NLE;Avg. NUMPAR;Avg. NOS;Avg. NOI;FS;LS;CV;\n')

    def join_etherscan_solmet(self):
        self._write_file_header()
        for obj in self.etherscan_json:
            fn = ".".join([self.get_sol_file_name(obj), 'out'])
            lines = open(fn, 'r').readlines()
            self.outf.write(';'.join([
                lines[1].rstrip(), 
                obj['firstseen'],
                obj['lastseen'], 
                obj['compiler_version'], '\n'
            ]))
        self.outf.close()

if __name__ == "__main__":
    m = MergeMetrics()
    m.join_etherscan_solmet()
    #print(m.get_sol_file_name({'address': '0x79a64dbe0a25390fa40a2eb819b934ccc7a06f45', 'name': 'ALLDigitalToken', 'compiler': 'Solidity', 'compiler_version': '0.4.25', 'balance': 0, 'txcount': '1', 'firstse    en': '2019-02-26T05:04:06.000Z', 'lastseen': '2019-02-26T05:04:06.000Z'}))
