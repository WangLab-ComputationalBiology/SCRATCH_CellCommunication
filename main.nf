#!/usr/bin/env nextflow
nextflow.enable.dsl = 2

include { SCRATCH_CellComm } from './subworkflow/local/SCRATCH_CellComm.nf'

if ( !params.input_seurat_object )
  exit 1, 'Please, provide a --input_seurat_object <PATH/TO/seurat_object.RDS> !'

workflow {
  log.info "\nParameters:\n\n  Input: ${file(params.input_seurat_object)}\n"

  // value channel so we can reuse it in multiple processes without into{}
  ch_input_seurat = Channel.value( file(params.input_seurat_object) )

  SCRATCH_CellComm(ch_input_seurat)
}

workflow.onComplete {
  log.info(
    workflow.success ?
      "\nDone! Open the following report in your browser -> ${launchDir}/${params.project_name}/cellcommunication/report/index.html\n" :
      "Oops... Something went wrong"
  )
}
