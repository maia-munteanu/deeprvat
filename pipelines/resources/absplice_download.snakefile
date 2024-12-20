import os
from pathlib import Path


genome = absplice_main_conf["genome"]

all_splicemap_tissues = absplice_main_conf["splicemap_tissues"]
if "tissue_cat" in absplice_main_conf.keys():
    all_splicemap_tissues.append(absplice_main_conf["tissue_cat"])
all_splicemap_tissues = sorted(set(all_splicemap_tissues))
all_splicemap_tissues = [
    tissue
    for tissue in all_splicemap_tissues
    if tissue in config_download["all_available_splicemap_tissues"]
]


def splicemap5(wildcards):
    path = Path(absplice_download_dir) / Path(config_download["splicemap_dir"])
    splicemaps = [
        path / f"{tissue}_splicemap_psi5_method=kn_event_filter=median_cutoff.csv.gz"
        for tissue in all_splicemap_tissues
    ]
    splicemaps = [str(x) for x in splicemaps]
    return splicemaps


def splicemap3(wildcards):
    path = Path(absplice_download_dir) / Path(config_download["splicemap_dir"])
    splicemaps = [
        path / f"{tissue}_splicemap_psi3_method=kn_event_filter=median_cutoff.csv.gz"
        for tissue in all_splicemap_tissues
    ]
    splicemaps = [str(x) for x in splicemaps]
    return splicemaps


def splicemap_dir_name(filename):
    return os.path.dirname(filename)


splicemap_v_mapper = {
    "hg38": "gtex_v8",
    "hg19": "gtex_v7",
}

list_outputs = list()


rule download_human_fasta:
    params:
        config_download["fasta"][genome]["url"],
    output:
        Path(absplice_download_dir) / config_download["fasta"][genome]["file"],
    conda:
        "./absplice.yaml"
    shell:
        "wget -O - {params} | gunzip -c > {output}"


list_outputs.append(
    Path(absplice_download_dir) / config_download["fasta"][genome]["file"]
)


rule download_splicemaps:
    params:
        version=splicemap_v_mapper[absplice_main_conf["genome"]],
        dirname=splicemap_dir_name(
            Path(absplice_download_dir) / config_download["splicemap"]["psi3"]
        ),
    output:
        splicemap_psi3=Path(absplice_download_dir)
        / config_download["splicemap"]["psi3"],
        splicemap_psi5=Path(absplice_download_dir)
        / config_download["splicemap"]["psi5"],
    conda:
        "./absplice.yaml"
    shell:
        "timeout 500000 splicemap_download --version {params.version} --splicemap_dir {params.dirname} --tissues {wildcards.tissue}"


list_outputs.append(
    expand(
        Path(absplice_download_dir) / config_download["splicemap"]["psi3"],
        genome=absplice_main_conf["genome"],
        tissue=absplice_main_conf["splicemap_tissues"],
    )
)
list_outputs.append(
    expand(
        Path(absplice_download_dir) / config_download["splicemap"]["psi5"],
        genome=absplice_main_conf["genome"],
        tissue=absplice_main_conf["splicemap_tissues"],
    ),
)
if absplice_main_conf["use_rocksdb"] == True:
    genome_mapper = {
        "hg38": "grch38",
        "hg19": "grch37",
    }

    rule download_rocksdb:
        params:
            version=genome_mapper[absplice_main_conf["genome"]],
        conda:
            f"./environment_spliceai_rocksdb.yaml"
        output:
            spliceai_rocksdb=directory(
                Path(absplice_download_dir)
                / config_download["spliceai_rocksdb"][genome]
            ),
        shell:
            "timeout 500000 spliceai_rocksdb_download --version {params.version} --db_path {output.spliceai_rocksdb} --chromosome {wildcards.chromosome}"

    list_outputs.append(
        expand(
            Path(absplice_download_dir)
            / config_download["spliceai_rocksdb"][genome],
            chromosome=config_download["chromosomes"],
        )
    )


rule all_download:
    input:
        list_outputs,


del splicemap5
del splicemap3
