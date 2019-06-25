# Solidity metrics

This project is a static analysis based metric calculator tool for Solidity smart contract programs.
It is a **Work In Progress**, supporting the following metrics

| Parameter | Description                                                       | Data Type          |
| --------- | ----------------------------------------------------------------- | ------------------ |
| Address   | The smart cotract Address on the ethereum blockchain              | address (20 bytes) |
| CV        | Compiler Version                                                  | String             |
| FS        | The First time the smart contract has been Seen on the blockchain | Date               |
| LS        | The Last time the smart contract has been Seen on the blockchain  | Date               |
| NA        | Number of Asserts                                                 | Number             |
| NC        | Number of contracts                                               | Number             |
| NCL       | Number of Comment Lines                                           | Number             |
| NF        | Number of Functions                                               | Number             |
| NFM       | Number of function modifiers                                      | Number             |
| NM        | Number of Mapping types                                           | Number             |
| NP        | Number of modifier Payable                                        | Number             |
| NRq       | Number of requires                                                | Number             |
| NRv       | Number of reverts                                                 | Number             |
| NSCL      | Number of Source Code Lines                                       | Number             |
| McCC      | McCabe’s cyclomatic complexity                                    | Number             |

## User instructions

This tool merges two metrics datasets: solmet(SolMet) and pyetherchain (EtherChain).
The join result is named SMEC (SolMet and EtherChain).

### Download and compute the metrics

```bash
cd examples

python3 01-download-SCs.py
python3 02-metrics-from-solmet.py # input_file: ./output/*.sol | output_file: ./output/*.out
python3 03-join_metrics.py # input_file: contracts_overview_file | output_file: solmetant.csv
```

### Data Analysis with Pandas and Python

```bash
cd examples
jupyter notebook &
```

```python
import pandas as pd
import seaborn as sns
import matplotlib.pyplot as plt

df = pd.read_csv('smec.csv', sep=';')
df.sort_values(by=['CV'], inplace=True)
df.head()

plt.figure(figsize=(20,5))
sns.swarmplot(x = 'CV',y='SLOC',data=df, size=5)
plt.show()

```

For further information, please follow this [link](http://svel.to/19y3).

<!--
## Building the tool

You can build the tool with Maven to get an executable jar file:

```
mvn package
```

## Using the tool

Usage is very simple, the built jar is executable.
It requires two parameters:

1.  a Solidity file or a folder containing Solidity files
2.  an output csv file path.

```
java -jar solmet-0.1.jar [input(s)] [output]
```

## Output

The output is a comma separated file containing the values of the calculated metrics for each analyzed contracts/libraries/interfaces.
-->

## Credits

The parser is based on the excellent antlr4 grammar available at https://github.com/solidityj/solidity-antlr4.

## References

1. A python interface to the ethereum blockchain explorer at www.etherchain.org. https://github.com/tintinweb/pyetherchain
2. SolMet-Solidity-parser. https://github.com/chicxurug/SolMet-Solidity-parser
