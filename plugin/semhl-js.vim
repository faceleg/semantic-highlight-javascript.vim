" A lot of code and ideas pillaged from:
" https://github.com/bigfish/vim-js-context-coloring/blob/master/ftplugin/javascript.vim
let s:shj = expand('<sfile>:p:h').'/../bin/shj-cli'

let s:region_count = 1

" parse functions
function! Strip(input_string)
    return substitute(a:input_string, '^\s*\(.\{-}\)\s*$', '\1', '')
endfunction

let b:variables = []

function SemanticHighlightWillBegin_javascript(bufferLines)
    "replace hashbangs (in node CLI scripts)
    let lineNumber  = 0
    for bufferLine in a:bufferLines
        if match(bufferLine, '#!') == 0
            "replace #! with // to prevent parse errors
            "while not throwing off byte count
            let a:bufferLines[lineNumber] = '//' . strpart(bufferLine, 2)
            break
        endif
        let lineNumber += 1
    endfor

    "fix offset errors caused by windows line endings
    "since 'a:bufferLines' does NOT return the line endings
    "we need to replace them for unix/mac file formats
    "and for windows we replace them with a space and \n
    "since \r does not work in node on linux, just replacing
    "with a space will at least correct the offsets
    if &ff == 'unix' || &ff == 'mac'
        let bufferText = join(a:bufferLines, "\n")
    elseif &ff == 'dos'
        let bufferText = join(a:bufferLines, " \n")
    else
        echom 'unknown file format' . &ff
        let bufferText = join(a:bufferLines, "\n")
    endif

    "noop if empty string
    if Strip(bufferText) == ''
        return
    endif

    let LEVEL = 0
    let START_POS = 1
    let END_POS = 2
    let ENCLOSED = 3
    let VARIABLES = 4
    let FUNCTION = 5

    try
        let b:scopeResults = system(s:shj, bufferText)
        let b:scopeData = eval(b:scopeResults)
        for scope in b:scopeData.scopes
           let b:variables = b:variables + scope[VARIABLES]
        endfor
    catch
        if g:js_context_colors_show_error_message || g:js_context_colors_debug
            echom "Syntax Error [SemanticHighlightWillHighlight_javascript]"
        endif
    endtry

endfunction

function! SemanticHighlightWillHighlight_javascript(arguments)
   " this logic is wrong - stopped here after realising I don't know if it
   " possible to highlight the same word with different colours
   let l:lastVarDeclaration = 0
   for variable in b:variables
      if variable.name == get(a:arguments, 'match') && variable.line == get(a:arguments, 'lineNumber')
         echo get(a:arguments, 'match') . '+' . variable.level
         return
      endif
   endfor
   echo get(a:arguments, 'match')
endfunction
