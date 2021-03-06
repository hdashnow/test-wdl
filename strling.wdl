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

  scatter (pair in zip(crams, str_extract.bin)) {

     call str_call_joint {
      input:
        ref_fasta = ref_fasta,
        cram = pair.left,
        bin = pair.right,
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
  File bin
  File bounds

  command {
    echo "${cram} ${bin}" > ${sample}-genotype.txt
    head ${bin}
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

