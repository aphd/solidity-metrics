from downloadSCs import EtherScanIoApi
from metricsFromSolmet import MetricsFromSolMet
from joinMetrics import MergeMetrics


def download():
    e = EtherScanIoApi()

    gap = 5760  # 1 block each  day
    start = 5000000
    end = 8000000
    #end = 8000000

    import random
    for block in range(start, end, gap):
        block = block + random.randint(-gap/2, +gap/2)
        print('\n### block:    ' + str(block) + ' ###\n')
        e.write_etherChain_fn(e.get_contracts_from_block(block))
    print("##### END DOWNLOAD ####")


def write_solidity_metrics():
    m = MetricsFromSolMet()
    m.write_solidity_metrics()
    print("##### END MetricsFromSolMet ####")


def merge_metrics():
    m = MergeMetrics()
    m.join_etherscan_solmet()
    print("##### END MergeMetrics ####")


def save_sol():
    import os
    e = EtherScanIoApi()
    output_path = e.config['DEFAULT']['output_path']
    os.system("mv " + output_path + '*.sol ./sol/')
    os.system("rm " + output_path + '*.out')


if __name__ == "__main__":
    download()
    write_solidity_metrics()
    merge_metrics()
    save_sol()
