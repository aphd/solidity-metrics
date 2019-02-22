import subprocess

jar_name = '../target/SolMet-1.0-SNAPSHOT.jar'
input_arg = './ebfe4723c636cf0a4d1374888f16736a986f5629_TeamUndisClosed.sol'
output_arg = './output.csv'
subprocess.call(['java', '-jar', jar_name, '-inputFile', input_arg, '-outFile', output_arg])