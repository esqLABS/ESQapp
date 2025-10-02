#' pc_block UI Function
#'
#' @description A shiny Module.
#'
#' @param id,input,output,session Internal parameters for {shiny}.
#'
#' @noRd
#'
#' @importFrom shiny NS tagList
mod_pc_block_ui <- function(id) {
  ns <- NS(id)
  tagList(
    uiOutput(ns("path_block"))
  )
}

#' pc_block Server Functions
#'
#' @noRd
mod_pc_block_server <- function(id, r){
  moduleServer(id, function(input, output, session){
    ns <- session$ns

    pc_path <- reactive({
      req(r$config$projectConfiguration)
      r$config$projectConfiguration$projectConfigurationFilePath
    })

    output$path_block <- renderUI({
      req(pc_path())
      path   <- pc_path()
      codeId <- ns("pc_path_code")
      btnId  <- ns("copy_btn")

      tags$div(
        class = "mb-3",  # spacing below the section title "Config file"
        tags$div(
          class = "position-relative bg-light px-3 py-2",
          style = "min-height: 48px; border-left: 0.2rem solid #7bbe6b;",
          # copy button (top-right)
          tags$button(
            id = btnId,
            type = "button",
            class = "btn btn-sm btn-outline-secondary position-absolute top-0 end-0 m-2 d-inline-flex align-items-center justify-content-center",
            style = "line-height:1; width:28px; height:28px; padding:0;",
            title = "Copy to clipboard",
            # inline SVG clipboard icon
            HTML('
              <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" fill="currentColor"
                   class="bi bi-clipboard" viewBox="0 0 16 16" aria-hidden="true">
                <path d="M10 1.5H6a.5.5 0 0 0-.5.5v1H4a2 2 0 0 0-2 2V13a2
                         2 0 0 0 2 2h8a2 2 0 0 0 2-2V5a2 2 0 0 0-2-2h-1.5V2a.5.5
                         0 0 0-.5-.5m-4 1A.5.5 0 0 1 6 2h4a.5.5 0 0 1 .5.5v1h1.5A1
                         1 0 0 1 13 5v8a1 1 0 0 1-1 1H4a1 1 0 0 1-1-1V5a1 1 0 0
                         1 1-1h1.5z"/>
                <path d="M9.5 3a.5.5 0 0 0 .5-.5V2h-4v.5a.5.5 0 0 0 .5.5z"/>
              </svg>
            '),
            onclick = sprintf("
              (async function(){
                const btn  = document.getElementById('%1$s');
                const code = document.getElementById('%2$s');
                if(!btn||!code) return;
                const text = code.innerText;
                try {
                  await navigator.clipboard.writeText(text);
                  const old = btn.innerHTML;
                  btn.innerHTML = '✓';
                  btn.classList.remove('btn-outline-secondary');
                  btn.classList.add('btn-success');
                  btn.disabled = true;
                  setTimeout(function(){
                    btn.innerHTML = old;
                    btn.classList.remove('btn-success');
                    btn.classList.add('btn-outline-secondary');
                    btn.disabled = false;
                  }, 1400);
                } catch(e) {
                  const range = document.createRange();
                  range.selectNodeContents(code);
                  const sel = window.getSelection();
                  sel.removeAllRanges(); sel.addRange(range);
                  try { document.execCommand('copy'); } catch(_) {}
                  sel.removeAllRanges();
                }
              })();
            ", btnId, codeId)
          ),
          # the code line (single-line, ellipsis, tooltip shows full path)
          tags$pre(
            class = "m-0",
            style = "
              font-size: 13px;
              font-family: ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, 'Liberation Mono','Courier New', monospace;
              white-space: nowrap;
              overflow: hidden;
              text-overflow: ellipsis;
              background: transparent;
              border: none;
              padding-right: 2rem;
            ",
            title = path,            # full path on hover
            tags$code(id = codeId, path)
          )
        )
      )
    })




  })
}

## To be copied in the UI
# mod_pc_block_ui("pc_block_1")

## To be copied in the server
# mod_pc_block_server("pc_block_1")
