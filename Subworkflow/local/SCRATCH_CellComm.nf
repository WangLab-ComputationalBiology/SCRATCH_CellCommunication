#!/usr/bin/env nextflow
nextflow.enable.dsl = 2

include {
  CELLCOMM_LIANA;
  CELLCOMM_CELLCHAT;
  CELLCOMM_NICHENET;
  // CELLCOMM_REPORT
} from '../../modules/local/Cell_Communication/main.nf'

workflow SCRATCH_CellComm {

  take:
    ch_input_seurat   // value channel from parent

  main:
    // QMD paths defined in nextflow.config
    def nb_liana    = Channel.fromPath(params.liana_qmd,    checkIfExists: true)
    def nb_cellchat = Channel.fromPath(params.cellchat_qmd, checkIfExists: true)
    def nb_nichenet = Channel.fromPath(params.nichenet_qmd, checkIfExists: true)
    // def nb_report   = Channel.fromPath(params.report_qmd,   checkIfExists: true)

    // 1) LIANA (single)
    def (li_report, li_figs, li_data, li_csv, li_done) =
      CELLCOMM_LIANA( ch_input_seurat.combine(nb_liana) )

    // 2) CellChat (single) - can run in parallel
    // def (cc_report, cc_figs, cc_data, cc_rds, cc_csv, cc_done) =
    //   CELLCOMM_CELLCHAT( ch_input_seurat.combine(nb_cellchat) )
    def (cc_report, cc_figs, cc_data, cc_rds, cc_done) =
      CELLCOMM_CELLCHAT( ch_input_seurat.combine(nb_cellchat) )


    // ---- Explicit barrier: wait for both LIANA + CellChat ----
    def LI_TICK = li_done.map{ 1 }.take(1)
    def CC_TICK = cc_done.map{ 1 }.take(1)
    def gated_seurat = ch_input_seurat
      .combine(LI_TICK)
      .combine(CC_TICK)
      .map { seurat, li_tick, cc_tick -> seurat }

    // // 3) NicheNet (single, receiver-loop inside QMD)
    // def (nn_report, nn_figs, nn_data, nn_summary, nn_done) =
    //   CELLCOMM_NICHENET( gated_seurat
    //     .combine(nb_nichenet)
    //     .combine(li_csv)
    //     .combine(cc_rds)
    //     .map { seurat, nb, liana_csv, cellchat_rds -> tuple(seurat, nb, liana_csv, cellchat_rds) }
    //   )

    def (nn_report, nn_figs, nn_data, nn_summary, nn_done) =
      CELLCOMM_NICHENET( 
        gated_seurat
          .combine(nb_nichenet)
          .combine(li_csv)
          .combine(cc_rds)
          .map { seurat, nb, liana_csv, cellchat_rds -> 
            tuple(seurat, nb, liana_csv, cellchat_rds) 
          },
        file("${projectDir}/assets/nichenet_resources", type: 'dir', checkIfExists: true)
      )

    // // 4) Final integrated Report -> report/index.html
    // // Stage tool outputs into report process so Report.qmd can embed them
    // def report_in = nb_report
    //   .combine(li_figs.collect())
    //   .combine(li_data.collect())
    //   .combine(cc_figs.collect())
    //   .combine(cc_data.collect())
    //   .combine(nn_figs.collect())
    //   .combine(nn_data.collect())
    //   .map { nb, liF, liD, ccF, ccD, nnF, nnD ->
    //     tuple(nb, liF, liD, ccF, ccD, nnF, nnD)
    //   }

    // CELLCOMM_REPORT(report_in)
}
