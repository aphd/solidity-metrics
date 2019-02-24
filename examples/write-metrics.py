import glob, re, subprocess 

class MetricsAPI(object):
    """
    Base Metrics Api implementation
    """
    def __init__(self):
        pass

    def write_solidity_metrics(self):
        jar = '../target/SolMet-1.0-SNAPSHOT.jar'
        for input in glob.glob("./output/*/*.sol"):
            output = re.sub('.sol$','.out' , input)
            subprocess.call(['java', '-jar', jar, '-inputFile', input, '-outFile', output])

if __name__ == "__main__":
    m = MetricsAPI()
    m.write_solidity_metrics()
