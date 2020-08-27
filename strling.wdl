workflow strling_joint {

  meta {
      author: "Harriet Dashnow"
      email: "h.dashnow@gmail.com"
      description: "Run STRling (github.com/quinlan-lab/STRling) in individual calling mode to detect and genotype STRs"
  }

  # Columns from the sample_set
  Array[String] crams

  File ref_fasta
  File ref_str

  scatter (cram in crams) {

    call str_extract {
      input:
        ref_fasta = ref_fasta,
        ref_str = ref_str,
        cram = cram,
    }

  }

  call str_merge {
    input:
      ref_fasta = ref_fasta,
      bins = str_extract.bin,
  }

  scatter (cram in crams) {

     call str_call_joint {
      input:
        ref_fasta = ref_fasta,
        bins = str_extract.bin,
        cram = cram,
        bounds = str_merge.bounds,
    }

  }

}

task str_extract {
  File ref_fasta
  File ref_str
  File cram
  File crai = cram + ".crai"
  String sample = basename(cram, ".cram")

  command {
    echo ${cram} > ${sample}.bin
  }
  runtime {
    memory: "4 GB"
    cpu: 1
    disks: "local-disk 100 HDD"
    preemptible: 3
    docker: "hdashnow/strling:latest"
  }
  output {
    File bin = "${sample}.bin"
  }
}

task str_merge {
  File ref_fasta
  Array[File] bins

  command {
    echo "${sep=' ' bins}" > strling-bounds.txt
  }
  runtime {
    memory: "4 GB"
    cpu: 1
    disks: "local-disk 100 HDD"
    preemptible: 3
    docker: "hdashnow/strling:latest"
  }
  output {
    File bounds = "strling-bounds.txt"
  }
}

task str_call_joint {
  File ref_fasta
  File cram
  File crai = cram + ".crai"
  String sample = basename(cram, ".cram")
  Array[String] bins
  File bounds

  command {
    source '/cromwell_root/gcs_transfer.sh'
    BIN=$(echo "${sep='\n' bins}" | grep ${sample}.bin)
    BIN_DIR=$(dirname $BIN)
    echo "gsutil cp $BIN ." > ${sample}-genotype.txt
    files_to_localize=(
    "biodata-fellow"   # project to use if requester pays
    "3" # max transfer attempts
    $BIN_DIR # container parent directory
    $BIN
    )
    localize_files "\${files_to_localize[@]}"
    ls
    ls $BIN
  }
  runtime {
    memory: "4 GB"
    cpu: 1
    disks: "local-disk 100 HDD"
    preemptible: 3
    docker: "hdashnow/strling:latest"
  }
  output {
    File output_genotype = "${sample}-genotype.txt"
  }
}

