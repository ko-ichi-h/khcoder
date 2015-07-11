---
global:
    all:                      Todo
    browse:                   Buscar
    cancel:                   Cancelar
    clear:                    Limpiar
    close:                    Cerrar
    cont_big_pros:            "Esta acción podría demorar\n ¿Desea continuar?"
    copy:                     Copiar
    copy_all:                 Copiar (todo)
    csv_f:                    Archivo CSV
    default:                  Predeterminado
    ok:                       OK
    paragraph:                Párrafos
    plot:                     Diagrama
    save:                     Guardar
    search:                   Buscar
    sentence:                 Oraciones
    spss_f:                   SPSS File
    tab_f:                    Delimitado por <
    wm_f:                     'Longitud de Variable CSV: para WordMiner'
    r_dont_close:             Mantener esta ventana abierta
    r_net_msg_fail:           'Error: imposible configurar las opciones.'
    words:                    Palabras
    select_a_file:            Seleccionar archivo
gui_errormsg::mysql:
    fatal:                   "Imposible acceder a sistema de la base de datos MySQL database system.\nKH Coder se cerrará."
gui_wait:
    done:                    "Proceso finalizado.\nTiempo total:"
gui_widget::bubble:
    bubble:                   'Diagrama de burbujas:'
    size:                     ' Tamaño de burbujas '
    standardize:              'Predeterminar tamaño:'
    variable:                 Tamaño de variables refleja recuento de palabras
    variance:                 'Varianza '
gui_widget::codf:
    browse_title:             Seleccionar archivo con reglas de codificación.
    cod_rule_f:               'Archivo de reglas de codificación:'
    no_file:                  No ha seleccionado un archivo
    reload:                   Cargar nuevamente
gui_widget::mail_config:
    change_font:              Configuración de fuente
    config:                   ver
    font:                     'Ajuste de fuente:'
    from:                     '    De: '
    note_fs:                  KH Coder es una herramienta de análisis cuantitativo de textos.
    other:                    Otros
    select_font:              'Tipo de fuente:'
    sendmail:                 Enviar correo al finalizar preprocesamiento
    size:                     'Tamaño:'
    smtp:                     '    Servidor SMTP: '
    to:                       '    Para: '
    use_heap:                 Datos en memoria para agilizar preprocesamiento
    display:                  Mostrar
    plot_size1:               'Tamaño de diagrama fijo:  Ancho'
    plot_size2:               '  Alto'
    font_size:                'Tamaño fijo de fuente en diagramas: '
gui_widget::r_font:
    bold:                     Negrita
    font_size:                'Tamaño de fuente:'
    pcnt:                     '% '
    plot_size:                '  Tamaño de diagrama:'
gui_widget::r_xy:
    cmp_plot:                 'Dimensiones del diagrama: '
    x:                        ' X'
    y:                        ' Y'
    origin:                   Mostrar el origen
    scaling:                  Escalamiento:
    none:                     Ninguno
    sym:                      Simétrico
    symbi:                    biplot simétrico
gui_widget::words:
    by_df:                    Filtrar palabras por Frecuencia de Documento
    by_pos:                   Filtrar palabras por POS
    by_tf:                    Filtrar palabras por Frecuencia de términos
    check:                    Verificar
    check_desc1:              Cantidad de palabras seleccionadas
    check_desc2:              ' '
    df_unit:                  '    Unidad de documento:'
    max_df:                   '  Max. FD:'
    max_tf:                   '  Max. FT:'
    min_df:                   '    Min. FT:'
    min_tf:                   '    Min. FT:'
    no_pos_selected:          'Error: No ha seleccionado POS.'
    unit:                     'Unidad:'
gui_window::about:
    close:                    Cerrar
    higuchi:                  'HIGUCHI, Koichi'
    kawabata:                 'KAWABATA, Akira'
    win_title:                Acerca de KH Coder
gui_window::cod_corresp:
    c_dd:                     Códigos x Documentos
    c_v:                      Códigos x Variables
    coding_unit:              'Unidad de codificación:'
    flt:                      'Mostrar etiqueta solo para códigos distintivos:'
    flw:                      'Filtrar códigos por valor chi cuadrado:'
    matrix_type:              'Entrada de Matriz de Datos:'
    na:                       No disponible
    sel3:                     '    * Seleccione al menos 3 códigos.'
    select_codes:             'Seleccionar código:'
    top:                      Top
    win_title:                'Opciones: Análisis de correspondencias de códigos'
    er_zero:                  'No se puede utilizar frecuencia 0 para este análisis.'
    er_unit:                  'Selección incorrecta de Unidad de Tabulación.'
gui_window::datacheck:
    auto_correct:             '   Autocorección de archivo de destino:'
    close:                    Cerrar
    correction_done:          '*** Se realizó la autorcorrección:'
    details:                  'Información detallada de problemas:'
    exec:                     ¡Ejecutar!
    file_backup:              '* El respaldo del archivo de destino se guardó como:'
    file_diff:                '* Se guardó la lista de modificación diff) como:'
    headmark:                 '*** '
    looks_complete:           Se corrigieron todos los problemas identificados.
    not_complete:             '* No se corrigieron algunos errores . Por favor, corrija manualmente.'
    print:                    Imprimir
    save_as:                  Guardar como
    save_as_win:              Guardando información detallada de los problemas
    saved:                    '*** Se guardó la información detallada de los problemas:'
    win_title:                Verificando archivo de destino
gui_window::dictionary:
    force_ignore:             'Forzar omisión de las siguientes palabras:'
    force_pick:               'Identificar las siguientes cadenas como palabras:'
    note1:                   "(*) Los cambios en \"Forzar omisión\" tendrán efecto\ncuando haga click en \"Ejecutar Preprocesamiento\" (nuevamente)."
    one_line1:                (una cadena en cada línea)
    one_line2:                (una palabra en cada línea)
    pos:                      'Seleccionar por Partes del Discurso:'
    win_title:                Seleccione las palabras para analizar
    use_file:                 Leer desde archivo
    file_error:               'El archivo especificado no existe:'
gui_window::doc_view:
    current_doc:              '* Documento actual: '
    highlight:                Destacar
    in_the_file:              'En el archivo:'
    in_the_results:           '  En los resultados:'
    n1:                       '>>'
    n2:                       '>>'
    p1:                       <<
    p2:                       <<
    win_title:                Documento
gui_window::force_color:
    add:                      Agregar
    delete:                   Eliminar
    desc:                     'Se destacarán las siguientes Palabras/Cadenas:'
    exists:                   Las Palabras/Cadenas ya existen.
    highlight:                'Destacar:'
    highlight_h:              destacar
    no_word:                  Por favor, ingrese las Palabras/Cadenas que se destacarán.
    string:                   cadena
    type:                     'Tipo:'
    type_h:                   Tipo
    win_title:                Destacar Palabras/Cadenas
    word:                     palabras
gui_window::main::inner:
    cases:                    Casos
    docs:                     'Documentos:'
    memo:                     'Memo:'
    target:                   'Archivo de destino:'
    tokens:                   'Tokens (en uso):'
    types:                    'Tipos (en uso):  '
    units:                    Unidades
gui_window::main::menu:
    open_nbl:                 'Seleccionar la clasificación del archivo de registro para ver'
    open_knb:                 'Seleccionar el modelo de archivo para ver'
    about:                    Acerca
    bayes_classi:             Clasificar Documetnos utilizando Modelo
    bayes_learn:              Construir Modelo desde Variable
    check:                    Verificar el archivo de destino
    check_classi:             Ver Registro de Clasificación
    check_learning:           Ver archivo de Modelo
    check_morpho:             Verificar los resultados de TermExtract
    close:                    Cerrar
    cluster:                  Análisis de Cluster
    coding:                   Codificación
    config:                   Configuración
    corresp:                  Análisis de correspondencias
    cross_vr:                 Tabla de contingencia
    desc_stats:               Estadísticos descriptivos
    doc_search:               Buscar Documentos
    doc_term_mtrx:            Exportar Matriz Documento-Palabra
    docs:                     Documentos
    docs_bayes:               Clasificador bayesiano ingenuo
    exec_sql:                 Ejecutar Sentencia SQL
    exit:                     Salir
    export:                   Exportar
    export_win_title:         Exportar proyecto actual a archivo *.khc.
    freq:                     Frecuencia
    freq_df:                  Distribución de Frecuencia de Documentos (FD)
    freq_tf:                  Distribución de Frecuencia de Términos (FT)
    h_cluster:                Análisis jerárquico de cluster
    help:                     Ayuda
    import:                   Importar
    import_save_path:         Guardando archivo de texto de destino (se creará la carpeta "coder_data" en la misma ruta).
    import_win_title:         Importar proyecto desde archivo *.khc.
    jac_mtrx:                 Matriz de similitud
    kwic:                     Concordancia KWIC
    man:                      Manual (PDF, en Japonés)
    mds:                      Escalamiento multidimensional
    netg:                     Red de coocurrencias
    new:                      Nuevo
    open:                     Abrir
    output_cod:               Exportar Matriz Documento-Código
    partial:                  Extracción parcial de texto
    plugin:                   Plugin
    prep:                     Preprocesamiento
    project:                  Proyecto
    read:                     Importar Variables
    run_prep:                 Ejecutar Preprocesamiento
    term_vec_mtrx:            Exportar Matriz Palabra-Contexto
    text_format:              Convertir Archivo de Destino
    tf_df:                    Diagrama FT-FD
    to_csv:                   Convertir a CSV
    tools:                    Herramientas
    use_chasen:               Usar ChaSen
    use_termextract:          Usar TermExtract
    var_list:                 Lista
    vars_heads:               Variables y Encabezados
    web:                      Información reciente (Web)
    word_ass:                 Asociación de palabras
    word_freq:                Lista de frecuencia
    word_search:              Búsqueda de palabras
    words:                    Palabras
    words_cluster:            Cluster de palabras
    words_selection:          Seleccione palabras para analizar
    som:                      Mapa autoorganizado
gui_window::morpho_check:
    details:                  Detalles
    note:                     Ingresar cadena o frase para verificar.
    sentence:                 Oración dividida
    win_title:                Resultados de Extracción de Palabras
gui_window::morpho_detail:
    base:                     lemma / lexema
    hyoso:                    Palabra
    katuyo:                   POS de Etiqueta 2
    next:                     Siguiente
    pos_cha:                  POS de Etiqueta 1
    pos_kh:                   POS de KH Coder
    previous:                 Anterior
    win_title:                'Resultados de la Extracción de Palabras: Detalles'
gui_window::project_edit:
    auto_detect:              Detección auto
    memo:                     'Memo:'
    target_char_code:         'Codificación del archivo de destino:'
    target_file:              'Archivo de destino:'
    win_title:                Nuevo Proyecto
gui_window::project_new:
    auto_detect:              Detección Auto
    browse_target:            Seleccioanr archivo de texto de destino
    memo:                     'Memo:'
    target_char_code:         'Codificación del archivo de destino:'
    target_column:            'Columna de destino:'
    target_file:              'Archivo de destino:'
    win_title:                Nuevo Proyecto
gui_window::project_open:
    del:                      Eliminar
    dir:                      Ruta
    edit:                     Editar
    memo:                     Memo
    new:                      Nuevo
    open:                     Abrir
    opened:                   "El proyecto ya está abierto.\nNo se puede realizar acción especificada."
    select_one:               Seleccionar un proyecto.
    target_file:              Archivo de destino
    win_title:                Gestor de proyectos
gui_window::r_plot:
    options:                  Configuración
    saving:                   'Guardar diagrama como:'
gui_window::r_plot::cod_corresp:
    win_title:                Análisis de correspondencias de Códigos
gui_window::r_plot::selected_netgraph:
    color:                    ' Color:'
    win_title:                Red de Coocurrencias (palabras seleccionadas)
gui_window::r_plot::word_corresp:
    col:                      color
    d:                        puntos
    d_l:                      puntos y etiquetas
    gray:                     escala de grises
    var:                      variables
    view:                     ' Ver:'
    win_title:                Análisis de correspondencias de Palabras
gui_window::r_plot_opt::cod_corresp:
    win_title:                'Configurar: Análisis de correspondencias de Códigos'
gui_window::r_plot_opt::selected_netgraph:
    win_title:                'Configurar: Red de Coocurrencias (palabras seleccionadas)'
gui_window::r_plot_opt::word_corresp:
    win_title:                'Configurar: Análisis de correspondencias de Palabras'
gui_window::sql_select:
    Server:                   '  Conectar a: '
    exec:                     Ejecutar
    max_rows:                 'Max columnas para mostrar:'
    rows:                     '  Columnas: '
    sql_error:                Error en Sentencia SQL.
    win_title:                Ejecutar Sentencias SQL
gui_window::sysconfig:
    apps:                     Aplicaciones
    browse_:                  ' '
    browse_chasen:            Abrir ChaSen.exe
    browse_mecab:             Abrir MeCab.exe
    browse_stanford_jar:      Abrir stanford-postagger.jar
    browse_stanford_tag:      Abrir modelo de archivo
    chasen:                   '"ChaSen" para textos en Japanés'
    config:                   Ingresar
    l_cn:                     Chino
    l_de:                     Alemán*
    l_en:                     Inglés
    l_es:                     Español *
    l_fr:                     Francés *
    l_it:                     Italiano *
    l_nl:                     Holandés*
    l_pt:                     Portugués *
    lang:                     '    Idioma:'
    mecab:                    '"MeCab" para textos en Japanés'
    need_inst:                ' *instalación separada'
    note_font:               "Ajuste de Fuente realizado.\nReiniciar KH Coder para aplicar los cambios."
    note_s:                   '* %s se reemplazará por los nombres de archivo de las URL'
    p_chasen.exe:             '    Ruta de "chasen.exe":'
    p_chasenrc:               '    Ruta de "chasenrc":'
    p_grammer.cha:            '    Ruta de "grammar.cha":'
    p_mecab.exe:              '    Ruta de "mecab.exe":'
    mecab_unicode:            'Diccionario Unicode'
    p_stanford_jar:           '    Ruta de *.JAR:'
    p_stanford_tag:           '    Ruta de *.TAGGER:'
    pdf:                      'Visor de PDF:'
    s_sheet:                  'Hoja de Cálculo (CSV/Excel):'
    stanford:                 Lematización con "Stanford POS Tagger"
    stemming:                 Stemming con "Bola de Nieve"
    stopwords:                '  Palabras vacías:'
    web_browser:              'Navegador:'
    win_title:                Configuración General
    words_ext:                Extracción de Palabras
gui_window::word_ass:
    18:                       chi cuadrado
    and:                      Y
    cond_h:                   Condicional
    direct:                   '#directo:'
    direct_code:              '#directo'
    filter:                   Filtro
    fr:                       Frecuencia
    go:                       Ejecutar
    hi:                       Lift
    hits:                     ' resultados: '
    hits0:                    ' resultados: 0'
    msg_l5:                   Se encontraron menos de 5 palabras. Se detuvo el procesamiento.
    net:                      Red
    no_code:                  '#ninguno'
    or:                       O
    pos_h:                    POS
    prob_h:                   Incondicional
    sa:                       Diferenciar
    sort:                     ' Ordenar:'
    sort_h:                   Ordenar
    unit:                     'Unidad:'
    win_title:                Asociación de Palabras
    word_h:                   palabra
gui_window::word_ass_opt:
    by_df:                    'Filtrar palabras por FD:'
    by_pos:                   'Filtrar palabras por POS:'
    min_df:                   '    FD Min. '
    top:                      '    Top '
    view:                     'Vista:'
    win_title:                'Filtrar: Asociación de palabras'
gui_window::word_conc:
    additional:               Opciones adicionales
    center:                   Conj.
    conj:                     '  Conj.:'
    currentDoc:               '* Buscar resultados: '
    hits:                     '  resultados: '
    l1:                       L1
    l2:                       L2
    l3:                       L3
    l4:                       L4
    l5:                       L5
    next:                     S
    ns:                       Ninguno
    pos:                      '  POS:'
    prev:                     A
    r1:                       R1
    r2:                       R2
    r3:                       R3
    r4:                       R4
    r5:                       R5
    retrieveNum1:             '  (recuperar LR '
    retrieveNum2:             Palabras)
    saving:                   Guardando los Resultados de Concordancia de KWIC...
    search:                   Buscar
    sort1:                    '  Tipo 1:'
    sort2:                    '  Tipo 2:'
    sort3:                    '  Tipo 3:'
    stats:                    Estadísticas
    viewDoc:                  Ver Doc
    viewing:                  ', Vista: '
    viewingUnit:              ' Unidades:'
    win_title:                Concordancia de KWIC
    word:                     'Palabra:'
gui_window::word_conc_coloc:
    additional:               '  + Opciones Adicionales'
    conj:                     '  Conj.:'
    filter:                   Filtro
    h_l_total:                LT
    h_pos:                    POS
    h_r_total:                RT
    h_score:                  Puntuación
    h_word:                   Palabra
    hits:                     '  Resultados: '
    l1:                       L1
    l2:                       L2
    l3:                       L3
    l4:                       L4
    l5:                       L5
    l_total:                  Total Izquierda
    pos:                      '  POS:'
    r1:                       R1
    r2:                       R2
    r3:                       R3
    r4:                       R4
    r5:                       R5
    r_total:                  Total Derecha
    sort:                     '  Ordenar:'
    total:                    Total
    win_title:                Estadísticas de colocaciones
    word:                     'Palabra:'
    span:                     '  extensión de Ventana:'
gui_window::word_conc_coloc_opt:
    filter_by_pos:            'Filtrar palabras por POS:'
    total_filt:               'Filtrar palabras por columna "Total":'
    no_less_than:             '      No menor a '
    view:                     'Vista:'
    top:                      '      Top '
    win_title:                'Filtrar: Estadísticas de colocaciones'
gui_window::word_conc_opt:
    0:                        Ninguno
    conj:                     '  Conj.:'
    l:                        L1-5
    l1:                       L1
    l2:                       L2
    l3:                       L3
    l4:                       L4
    l5:                       L5
    opt1:                     Condición 1
    opt2:                     Condición 2
    opt3:                     Condición 3
    pos:                      '  POS:'
    position:                 'Posición:'
    preface1:                 Puede añadir condiciones de búsqueda como "Hay una palabra A en L1."
    preface2:                 'Para añadir condiciones, primero especifique "Posición".'
    r:                        R1-5
    r1:                       R1
    r2:                       R2
    r3:                       R3
    r4:                       R4
    r5:                       R5
    rl:                       LR1-5
    win_title:                Opciones adicionales de concordancia de KWIC
    word:                     '  Palabra:'
gui_window::word_corresp:
    biplot:                   Biplot
    check_var_unit:           'Error: seleccione variables con la misma unidad.'
    dim:                      'Dimensión '
    eig:                      Cor ^2
    exp:                      Explicado
    flt:                      'Mostrar etiquetas solo para palabras distintivas:'
    flw:                      'Filtrar palabras por valor chi-cuadrado:'
    matrix:                   'Ingresar Matriz de Datos:'
    na:                       No disponible
    nav:                      perdido
    option_ca:                'Opciones de análisis de correspondencias'
    option_words:             'Seleccionar palabras'
    plot:                     ' '
    select_3words:            Error seleccione al menos 3 palabras.
    select_pos:               'Error: Seleccione al menos 1 POS.'
    select_var:               'Error: Seleccione al menos 1 variable.'
    too_many1:                ' '
    too_many2:                se diagramará las palabras.
    too_many3:                Se recomienda mantener la cantidad de palabras cerca de 100 o 150.
    too_many4:                ¿Desea continuar?
    top:                      Top
    unit:                     'Unidad de Tabulación:'
    w_d:                      Palabras x Documentos
    w_v:                      Palabras x Variable(s)
    win_title:                'Opciones: Análisis de correspondencias de Palabras'
    words:                    ' '
gui_window::word_df_freq:
    c_freq:                   "Acumulado\nFrecuencia"
    c_pcnt:                   "Acumulado\nPorcentaje"
    descr:                    Descriptivos
    df:                       FD
    freq:                     Frecuencia
    freq_tab:                 Tabla de Frecuencia
    pcnt:                     Porcentaje
    units:                    '  Unidades de recuento:'
    win_title:                Distribución de Frecuencia de Documento
gui_window::word_df_freq_plot:
    log:                      'Ejes logarítmicos:'
    none:                     Ninguno
    saving:                   Guardar diagrama como...
    win_title:                Diagrama de Distribución de Frecuencia de Documento
    x:                        FD (X)
    xy:                       FD (X) y Frecuencia (Y)
gui_window::word_freq:
    c_freq:                   "Acumulado\nFrecuencia"
    c_pcnt:                   "Acumulado\nPorcentaje"
    descr:                    Descriptivos
    freq:                     Frecuencia
    freq_tab:                 Tabal de Frecuencia
    pcnt:                     Porcentaje
    refresh:                  Actualizar
    tf:                       FT
    win_title:                Distribución de Frecuencia de Términos
gui_window::word_freq_plot:
    log:                      'Ejes logarítmicos:'
    none:                     Ninguno
    saving:                   Guardar diagrama como...
    win_title:                Diagrama de Distribución de Frecuencia de Términos
    x:                        FT (X)
    xy:                       FT (X) y Frecuencia (Y)
gui_window::word_list:
    count:                    'Qué contar:'
    csv:                      Separado por coma (*.csv)
    df:                       Frecuencia de Documento
    file_type:                'Tipos de archivos:'
    hinshi:                   Por etiquetas POS
    single:                   Una columna
    tf:                       Frecuencia de términos
    top150:                   Top 150
    type:                     'Tipo de lista:'
    win_title:                'Opciones: Lista de Frecuencia'
    xls:                      Excel (*.xls)
gui_window::word_search:
    and:                      Y
    back:                     Coincidencia anterior
    baseform:                 Buscar forma base
    comp:                     Coincidencia Parcial
    conj:                     Conj.
    forw:                     Coincidencia posterior
    freq:                     Frecuencia
    kwic:                     Concordancia de KWIC
    morph:                    Palabra
    or:                       O
    part:                     Coincidencia Parcial
    pos:                      POS
    pos_conj:                 POS / Conj.
    search:                   Buscar
    view_conj:                Ver Conj.
    win_title:                Buscar Palabras
    df:                       Palabra
gui_window::word_tf_df:
    df:                       Document Frecuencia
    log:                      '  Ejes logarítmicos:'
    none:                     Ninguno
    saving:                   Guardar diagrama como...
    tf:                       Frecuencia de Términos
    units:                    'Recuento de Unidades:'
    win_title:                Diagrama de FT-FD
    x:                        FT(X)
    xy:                       FT(X) y FD(Y)
kh_datacheck:
    corrected:                Se corrigeron todos los problemas identificados.
    error_c1:                 Algunas líneas contienen caracteres ilegibles
    error_c2:                 Símbolos inapropiados
    error_m1:                 Línea de encabezado muy larga (no se puede corregir automaticamente)
    error_mn:                 'Uso incorrecto de etiquetas H1 - H5 (no se puede corregir automaticamente)'
    error_n1a:                Líneas muy larga
    error_n1b:                Líneas muy larga (no se puede corregir automaticamente)
    errors_detail:            'Se encontraron los siguientes problemas(detalles):'
    errors_summary:           'Se encontraron los siguientes problemas(resumen):'
    lines:                    ' línea(s)'
    looks_good:              "No se encontraron problemas.\n Proceda al preprocesamiento."
    error_charcode:           "No se puede detectar el código de caracteres del archivo de destino. Especifique el código de caracteres. Vaya a [Proyecto] [Abrir] en la barra de menú y haga click en \"editar\" para especificar  el código."
kh_morpho::chasen:
    error:                    'Error fatal: no se puede ejecutar ChaSen.'
    error_config:             'Error fatal: no se encuentra ChaSen.'
kh_morpho::mecab:
    error:                    'Error fatal: no se puede ejecutar MeCab.'
    error_config:             'Error fatal: no se encuentra MeCab.'
    illegal_bra:              'marcado incorrecto con <>'
kh_morpho::stanford:
    error:                    'Error fatal: no se puede ejecutar Stanford POS Tagger.'
    error_config:             'Error fatal: no se encuentra JStanford POS Tagger.'
    no_java:                  'Error fatal: no se encuentra JAVA.'
kh_morpho::stemming:
    error:                    'Error fatal: Imposible realizar stemming.'
kh_sysconfig::chasen:
    path_error:               No se encuentra Chasen.exe
kh_sysconfig::mecab:
    path_error:               No se encuentra MeCab.exe
kh_sysconfig::stanford:
    path_error:               No se encuentra Stanford POS Tagger
mysql_words:
    df:                       FD
    mean_df:                  Promedio de FD
    mean_tf:                  Promedio de FT
    pos:                      POS
    std_dev_df:               Desv. estándar de FD
    std_dev_tf:               Desv. estándar de FT
    tf:                       FT
    types:                    Tipos de palabras (n)
    words:                    Palabras
    excel_limit:              "Imposible exportar todos los registros. Límite de registro de archivos Excel es de 65.536.\nSeleccione CSV para Exportar todos los datos."
gui_widget::cls4mds:
    cluster_color:            'Indicar clusters con colores diferentes'
    cls_num:                  'Cantidad de clusters:'
    2_12:                     '(de 2 a 12)'
    adj:                      'Clusters adyacentes'
gui_widget::r_mds:
    method:                   'Método:'
    dist:                     '  Distancia:'
    dim:                      'Dimensiones:'
    1_3:                      '(de 1 a 3)'
gui_window::word_mds:
    units_words:              'Seleccionar la unidad & palabras'
    mds_opt:                  'Opciones de Escalamiento Multidimensional'
    plot:                     ' '
    win_title:                'Opciones: Escalamiento Multidimensional de Palabras'
    select_5words:            Error: Seleccione al menos 5 palabras.
    error_dim:                Error: Especifique de 1 a 3 dimensiones
    dim:                      Dimension
    omit:                     "Se omitieron las siguientes palabras/códigos del análisis:\n"
    r_alpha:                  'Colores traslúcidos (no apropiado para EMF/EPS)'
gui_window::r_plot_opt::word_mds:
    win_title:                'Configurar: Escalamiento Multidimensional de Palabras'
gui_window::r_plot::word_mds:
    win_title:                'Escalamiento Multidimensional de Palabras'
gui_window::cod_mds:
    win_title:                'Opciones: Escalamiento Multidimensional de Códigos'
    sel5:                     '    * Seleccione al menos 5 códigos.'
    sel5_e:                   Error Seleccione al menos 5 códigos.
gui_window::r_plot::cod_mds:
    win_title:                'Escalamiento Multidimensional de códigos'
gui_window::r_plot_opt::cod_mds:
    win_title:                'Configurar: Escalamiento Multidimensional de códigos'
gui_widget::r_cls:
    method:                   'Método:'
    ward:                     'Ward'
    average:                  'Promedio'
    complete:                 'Completo'
    clara:                    'CLARA'
    dist:                     '  Distancia:'
    n_cls:                    'N de clusters:'
    color:                    'Colores diferentes'
    stand:                    'Estandarizar:'
    none:                     'Ninguno'
    by_words:                 'Por Palabras'
    by_docs:                  'Por Documentos'
    tfidf:                    '  FT-FID:'
gui_window::word_som:
    win_title:                'Opciones de Mapa autoorganizado'
    cluster:                  ' '
    u_w:                      'Seleccionar unidad & palabras'
    opt:                      'Opciones de Mapa autoorganizado'
    time_warn:                "Podría tomar horas e incluso días construir el \nmapa autoorganizado"
gui_widget::r_som:
    n_nodes1:                 'Cantidad de nodos (por lado):'
    cluster_color:            'Nodos por cluster'
    cls_num:                  'Cantidad de clusters:'
    2_12:                     '(de 2 a 12)'
    hex:                      'hexágonogono'
    sq:                       'cuadrado'
    p_nodes:                  'Diagrama: '
    rlen:                     'Cantidad de pasos:'
gui_window::r_plot::word_som:
    cls:                      'Clusters'
    gray:                     'Escala de grises'
    freq:                     'Frecuencia'
    umat:                     'U-matriz'
    views:                    ' Color: '
    win_title:                'Mapa autoorganizado de Palabras'
gui_window::r_plot_opt::word_som:
    win_title:                'Configurar: Mapa autoorganizado de Palabras'
gui_window::word_cls:
    u_w:                      'Seleccionar unidad & palabras'
    opt:                      'Opciones de Análisis de Cluster'
    cluster:                  ' '
    win_title:                'Opciones: Análisis Jerárquico de Cluster de Palabras'
    last1:                    'último '
    last2:                    ''
    first1:                   'primero '
    first2:                   ''
    agglomer:                 'Etapas de aglomeración'
    hight:                    'Coeficientes (disimilaridad)'
    note1:                    "* Los valores numéricos en el diagrama indican\n  la cantidad de clusters en cada etapa"
gui_window::r_plot::word_cls:
    ward:                     'ward'
    ave:                      'promedio'
    clink:                    'clink'
    method:                   ' método:'
    agglomer:                 'Aglomeración'
    win_title:                'Análisis Jerárquico de Cluster de Palabras'
gui_window::r_plot_opt::word_cls:
    err_no_auto:              'En esta ventana no puede especificar "Automático". Especifique valores numéricos.'
    win_title:                'Configurar: Análisis Jerárquico de Cluster de Palabras'
gui_window::cls_height::word:
    win_title:                'Aglomeración: Análisis Jerárquico de Cluster de Palabras'
gui_window::cls_height:
    plotting:                 ' Etapas: '
    f50:                      '<< primeros 50'
    all:                      'todo'
    l50:                      'últimos 50 >>'
    save_as:                  'Guardar diagrama como:'
gui_window::cod_cls:
    win_titile:               'Opciones: Análisis Jerárquico de Cluster de códigos'
gui_window::r_plot_opt::cod_cls:
    win_title:                'Configurar: Análisis Jerárquico de Cluster de códigos'
gui_window::r_plot::cod_cls:
    win_titile:               'Análisis Jerárquico de Cluster de códigos'
gui_window::cls_height::cod:
    win_title:                'Aglomeración: Análisis Jerárquico de Cluster de códigos'
gui_window::cod_som:
    win_title:                'Opciones: Mapa autoorganizado de códigos'
gui_window::r_plot::cod_som:
    win_title:                'Mapa autoorganizado de códigos'
gui_window::r_plot_opt::cod_som:
    win_title:                'Configurar: Mapa autoorganizado de códigos'
gui_widget::r_net:
    filter_edges:             'Filtrar bordes:'
    e_top_n:                  'Top'
    e_jac:                    'coeficiente Jaccard >= '
    or_more:                  ''
    thicker:                  'Líneas más gruesas para bordes más fuertes'
    larger:                   'Nodos más grandes para Palabras más Frecuentes'
    larger_c:                 'Nodos más grandes para Códigos más Frecuentes'
    larger_font:              'Tamaño de fuente variable *Para imprimir en EMF/EPS/PDF'
    smaller:                  'Nodos más pequeños'
    min_sp_tree:              'Destacar el árbol recubridor mínimo'
    min_sp_tree_only:         'Dibujar solo el árbol recubridor mínimo'
    gray_scale:               'Escala de grises (centralidades & comunalidades)'
    fix_lab:                  'Evitar superposición de etiquetas'
gui_window::word_netgraph:
    u_w:                      'Seleccionar unidad & palabras'
    use:                      ''
    net_opt:                  'Opciones de Red de Coocurrencias'
    e_type:                   'Tipo de Bordes:'
    w_w:                      'Palabras - Palabras'
    w_v:                      'Palabras - variables / encabezados'
    var:                      'Variable / Encabezados:'
    win_title:                'Opciones: Red de Coocurrencias de Palabras'
gui_window::r_plot_opt::word_netgraph:
    win_title:                'Configurar: Red de Coocurrencias de Palabras'
gui_window::r_plot::word_netgraph:
    col:                      'color'
    gray:                     'Escala de grises'
    cnt_b:                    'Centralidad: intermediación'
    cnt_d:                    'Centralidad: grado'
    cnt_v:                    'Centralidad: eigenvector'
    com_b:                    'Comunalidades: intermediación'
    com_r:                    'Comunalidades: camino aleatorio'
    com_m:                    'Comunalidades: modularidad'
    none:                     Ninguno
    color:                    ' color:'
    win_title:                'Red de Coocurrencias of Palabras'
gui_window::cod_netg:
    win_title:                'Opciones: Red de Coocurrencias de códigos'
    c_c:                      'códigos - códigos'
    c_v:                      'códigos - variables / Encabezados'
gui_window::r_plot_opt::cod_netg:
    win_title:                'Configurar: Red de Coocurrencias of códigos'
gui_window::r_plot::cod_netg:
    win_title:                'Red de Coocurrencias of códigos'
gui_window::cod_count:
    win_title:                'Frecuencia of códigos'
    go_c:                     'Ejecutar'
    h_code:                   'códigos'
    h_freq:                   'Frecuencia'
    h_pcnt:                   'Porcentaje'
    error_cod_f:              'Error: Seleccione una regla de codificación.'
kh_cod::func:
    no_codes:                 '#no_códigos'
    n_docs:                   'N de Documentos'
    n_cases:                  'N de Documentos'
    total:                    'Total'
    chisq:                    'chi-cuadrado'
gui_widget::tani2:
    unit_c:                   'Unidad de codificación:'
    unit_t:                   '    Unidad de tabulación:'
gui_window::cod_outtab:
    win_title:                'Codificación: Tabla cruzada'
    cells:                    '    Cells:'
    unit_cod:                 'Unidad de codificación:'
    var:                      '   Tabla cruzada:'
    f_p:                      'ambas'
    f:                        'Frecuencia'
    p:                        'Porcentaje'
    run:                      'Ejecutar'
    er_ill:                   'Error: parámetros incorrectos'
    line_all:                 'todos'
    line_select:              'seleccionar'
    line:                     ' línea:'
    map:                      'mapa: '
gui_window::cod_jaccard:
    win_title:                'Codificación: Coeficientes de Jaccard'
    unit_cod:                 '  Unidad de codificación:'
    copy_sel:                 'Copiar (seleccionado)'
gui_window::cod_out::csv:
    save_as:                  'Guardar matriz Documento-Código como *.csv'
    win_title:                'Exportar matriz Documento-Código: CSV'
gui_window::cod_out::spss:
    save_as:                  'Guardar matriz Documento-Código como *.sps'
    win_title:                'Exportar matriz Documento-Código: SPSS'
gui_window::cod_out::tab:
    save_as:                  'Guardar matriz Documento-Código como *.txt'
    win_title:                'Exportar matriz Documento-Código: Delimitado por tabulación'
    tab_delimited:            'Delimitado por tabulación'
gui_window::cod_out::var:
    save_as:                  'Guardar matriz Documento-Código como *.cvs'
    win_title:                'Exportar matriz Documento-Código: Largo de Variable CSV'
gui_window::doc_search:
    win_title:                'Buscar Documentos'
    run:                      'Ejecutar'
    unit:                     'Unidad:'
    no_sort:                  'no ordenar'
    tf:                       'ft'
    tf_M_idf:                 'ft*fid'
    tf_D_idf:                 'ft/fid'
    error_no_code:            'Seleccione al menos 1 código.'
kh_cod::search:
    codes:                    '* códigos agregados a este documento (en el archivo actual de regla de codificación ):'
    no_codes:                 '#ninguno'
    direct:                   '#directo'
gui_widget::select_a_var:
    heading:                  'Encabezado'
    na:                       'n / a '
gui_window::doc_cls:
    verb:                     ''
    select_3words:            'Seleccione al menos 3 Palabras.'
    fail:                     'No se pudo calcular los clusters.'
    win_title:                'Opciones: Análisis de cluster de Documentos'
gui_window::doc_cls_res:
    win_title:                'Análisis de cluster de Documentos'
    docs_in_clusters:         'Documentos en cada cluster'
    h_cls_id:                 'cluster'
    h_doc_num:                'Documentos'
    docs:                     'Documentos'
    bal_docs:                 "Buscar Documentos en el cluster.\n[doble click]"
    words:                    'Palabras'
    bal_words:                "Buscar Palabras distintivas del cluster\n[shift + doble click]"
    agglm:                    'Etapas de aglomeración'
    h_stage:                  'etapa'
    h_cls1:                   'cluster 1'
    h_cls2:                   'cluster 2'
    h_coeff:                  'coeficientes'
    both:                     '1 & 2'
    only1:                    'solo 1'
    only2:                    'solo 2'
    bal_agg_docs:             "Buscar Documentos en la etapa\n[doble click]"
    m_wrd:                    'Ward'
    m_ave:                    'Promedio'
    m_clk:                    'CLink'
    config:                   'Configuración'
    save:                     'Guardar los resultados como una variable'
    cluster:                  'Cluster'
    na:                       'n/d'
gui_window::doc_cls_res_sav:
    desc:                     'Guardando los resultados del análisis de cluster como variable.'
    name:                     'Nombre de la Variable:'
    specify_var:              'Especifique el nuevo nombre de la variable'
    win_title:                'Guardar cluster como nueva variable'
gui_window::doc_cls_res_opt:
    win_title:                'Configurar: Análisis de cluster de Documentos'
gui_window::cls_height::doc:
    win_title:                'Aglomeración: Análisis de cluster de Documentos'
    overwr:                   'Podría sobreescribir este archivo: '
gui_window::morpho_crossout:
    output:                   ''
gui_window::morpho_crossout::csv:
    er_no_pos:                'Error: Seleccione al menos 1 POS'
    saving:                   'Guardar matriz documento-palabra como:'
    win_title:                'Exportar matriz documento-palabra: CSV'
gui_window::morpho_crossout::spss:
    win_title:                'Exportar matriz documento-palabra: SPSS'
gui_window::morpho_crossout::tab:
    tabdel:                   'Delimitado por tabulación'
    win_title:                'Exportar matriz documento-palabra: Delimitado por tabulación'
gui_window::morpho_crossout::var:
    win_title:                'Exportar matriz documento-palabra: Largo de Variable CSV'
gui_window::contxt_out:
    words:                    'Palabras'
    words4cntxt:              'Palabras para Clacular los Vectores de Contexto'
    options:                  'Unidades & Pesos'
    use:                      ''
gui_window::contxt_out::csv:
    saving:                   'Guardar matriz Word-Context como:'
    win_title:                'Exportar matriz Word-Context: CSV'
gui_window::contxt_out::spss:
    win_title:                'Exportar matriz Word-Context: SPSS'
gui_window::contxt_out::tab:
    win_title:                'Exportar matriz Word-Context: Delimitado por tabulación'
gui_window::txt_pickup:
    win_title:                'Extraer Texto Parcial'
    headings:                 'Extraer Encabezados'
    headings_name:            '  '
    codes:                    'Extraer Documentos con Código Específico'
    unit:                     'Unidad de codificación'
    higher:                   'Incluir Encabezados de nivel superior'
    error_no_headings:        'Seleccione al menos 1 Encabezado'
    saving:                   'Extraer texto parcial: guardar como'
gui_window::txt_html2csv:
    win_title:                'Convertir a CSV'
    unit:                     'Qué unidad debería considerarse como fila/caso de CSV'
    select:                   'Selección:'
    saving:                   'guardar archivo CSV como'
gui_window::outvar_read:
    unit:                     'Unidad de variables:'
    no_such_file:             'Error: archivo no encontrado'
gui_window::outvar_read::csv:
    open:                     'Seleccionar el archivo que contiene variables'
    csv:                      'Archivo CSV:'
    win_title:                'Leer variables desde el archivo CSV'
gui_window::outvar_read::tab:
    tabdelf:                  'Archivo delimitado por tabulación'
    open:                     'Seleccionar el archivo que contiene variables'
    tabdel:                   'Archivo delimitado por tabulación'
    win_title:                'Leer variables desde el archivo delimitado por tabulación'
gui_window::outvar_list:
    win_title:                'Lista de Variables & Encabezados'
    headings:                 'Encabezados'
    vars:                     'Variables'
    h_unit:                   'unidades'
    h_name:                   'variables'
    del:                      'Eliminar'
    export:                   'Exportar'
    read:                     '*Importar'
    csv:                      'Archivo CSV'
    tabdel:                   'Delimitado por tabulación'
    values:                   'Valores & etiquetas de valor: '
    h_value:                  'valor'
    h_label:                  'etiqueta'
    h_freq:                   'Frecuencia'
    save:                     'guardar etiquetas'
    docs:                     'Documentos'
    words:                    '*Palabras'
    selected:                 'valor seleccionado'
    catalogue_xls:            'catálogo: Excel'
    catalogue_csv:            'catálogo: CSV'
    help_words:               "Buscar palabras distintivas del valor.\n[Shift + doble click]"
    unit:                     'Unidad:'
    help_docs:                "Buscar Documentos con el valor seleccionado\n[Doble click]"
    error_sel_a_var:          'Error: Seleccione una variable.'
    mspgoth:                  'MS PGothic'
    error_sel_a_vv:           'Error: Seleccione una variable y un valor.'
    error_hd1:                'Imposible eliminar encabezados.\nModifique directamente el archivo de destino.'
    del_ok:                   '¿Eliminar variables seleccionadas?'
    error_units:              'Imposible exportar variables con múltiples unidades.'
    error_hd2:                'Imposible exportar Encabezados.\nConsidere utilizar el comando de "Extraer Texto Parcial"'
    saving:                   'guardar variables como'
gui_window::hukugo:
    win_title:                'Clusters de palabras: ChaSen'
    run:                      'ejecutar'
    h_huku:                   'cluster'
    h_freq:                   'Frecuencia'
    whole:                    'Lista completa'
gui_window::use_te:
    win_title:                'Derechos de copia de TermExtract'
    desc:                     'Se utilizará TermExtract en esta función.'
    web:                      'Sitio web de TermExtract:'
    about:                    'Sobre TermExtract:'
gui_window::use_te_g:
    win_title:                'Clusters de palabras: TermExtract'
    run:                      'Ejecutar'
    h_hukugo:                 'cluster'
    h_score:                  'Puntaje'
gui_window::bayes_learn:
    win_title:                'Construir modelo desde variable (utilizar variable como datos de entrenamiento)'
    add2exists:               'Adjuntar resultados actuales al archivo modelo existente'
    cr_validate:              'Realizar validación cruzada'
    savelog:                  'guardar registro de clasificación'
    savecls:                  'guardar clasificación de resultados como variable'
    vname:                    'Variable:'
    error_f20:                'Error: especifique de 2 a 20 el número de pliego'
    error_var:                'Error: Seleccione una variable.'
    error_exists:             'Error: la variable ya existe'
    select_exist:             'Seleccione el archivo modelo para adjuntar'
    saving_new:               'Guardando el modelo como'
    saving_log:               'Guardando el registro de clasificación como'
    error_no_words:           'Error: Palabras no disponibles en la configuración actual.'
    done:                     'Construcción del modelo completada.'
    docs:                     'Cantidad de Documentos utilizados como datos de entrenamiento:'
    docs_total:               'Cantidad total de Documentos:'
    accuracy:                 'Precisión:'
    verb4wid:                 ''
gui_widget::words_bayes:
    unit:                     'Unidad de Clasificación:'
    var:                      'Variable:'
    n_a:                      'no disponible'
gui_window::bayes_view_knb:
    win_title:                'Ver un archivo modelo:'
    n_docs:                   'Documentos procesados:'
    n_types:                  ' Tipos de Palabras:'
    search:                   'Buscar'
    whole:                    'Lista completa'
    variance:                 Varianza
kh_nbayes::cv_predict:
    cross_validation:         '(validación cruzada)'
kh_nbayes::Util:
    prior:                    '[probabilidad anterior]'
gui_window::bayes_predict:
    win_title:                'Clasificar los Documentos utilizando un archivo modelo'
    unit:                     'Unidad de Clasificación:'
    model_file:               'Archivo modelo:'
    var_name:                 'nombre de la Variable:'
    var_desc:                 '    * Los resultados de clasificación se guardarán como variable.'
    save_log:                 'guardar detalles de clasificación al archivo de registro'
    opening_model:            'Abriendo archivo modelo...'
    er_no_such_file:          'Error: por favor, especifique un nombre de archivo correcto.'
    er_specify_name:          'Error: por favor, especifique un nombre para la variable.'
    er_exists:                'Error: la variable ya existe.'
    saving_log:               'Guardando los detalles de clasificación como:'
gui_window::bayes_view_log:
    win_title:                'Clasificación details file:'
    model_file:               'Archivo modelo:'
    saved_var:                ' Variable guardada:'
    unit:                     ' Unidad de Clasificación:'
    doc_id:                   ' No. Doc '
    search_words:             'Buscar Palabras:'
    class:                    'clase:'
    higher_left:              ' * Los puntajes más altos se encuentran a la izquierda.'
    word:                     'Palabras'
    freq:                     'Frecuencia'
    variance:                 'varianza'
    run:                      'ejecutar'
kh_nbayes:
    classified_as:            'clasificado como'
    classs:                   'clase'
    correct_insts:            'Casos clasificados correctamente'
    kappa:                    'Estadístico Kappa: '
kh_project:
    no_target_file:           'No se puede encontrar archivo de destino'
kh_projects:
    already_registered:       'El archivo ya se encuentra registrado como proyecto'
gui_errormsg::file:
    could_not_open_the_file:  "No se pudo abrir el archivo.\nKH Coder se cerrará.\n* "
kh_cod:
    not_coding_rules:         'El archivo seleccionado no parece un archivo de reglas de codificación'
kh_r_plot:
    illegal_plot_size:        'Tamaño de diagrama incorrecto'
    faliled_in_plotting:      "Imposible diagramar con R\n\n"
mysql_ready:
    error_in_mysql_bunr:      "Ocurrió un error con la base de datos: bun_r table\nKH se cerrará"
    too_long_sentence:        "Error: hay oraciones demasiado extensas. ( > 65535 )\nKH se cerrará."
kh_cod::a_code:
    syntax_error:             "Error de sintaxis en la regla de codificación:"
kh_cod::a_code::atom::code:
    no_code_error:            "Error de sintaxis. No se encuentra el código: "
mysql_outvar::read:
    records_error:            "Número de registros no coincide.\nAbortando el proceso."
    midashi_error:            'No se puede utilizar "Encabezado1" - "Encabezado5" como el nomber de la variable.'
    overwrite_vars:           "Existe una variable con el mismo nombre.\n¿Sobreescribir?\n\n"
mysql_ready::dump:
    too_long_word1:            "Hay palabras muy largas. ( > 255 )\n\nKH Coder reconoce solo los primeros 255 caracteres.\nLas alabras se registraron en el siguiente archivo: \n"
    too_long_word2:            "Click en OK para continuar el preprocesamiento."
mysql_getheader:
    error:                     "Error al procesar los documentos.\n\nVerifique el uso de las etiquetas H1 - H5 en el archivo de destino.\nUtilice el comando \"Verificar el archivo de destino\"."
gui_window::r_plot::doc_cls:
    win_title:                 "Dendrograma de Documentos"
gui_window::r_plot_opt::doc_cls:
    win_title:                 "Configurar: Dendrograma de Documentos"
mysql_ready::check:
    error:                     "Error con la base de datos: "
gui_window::r_plot::cod_mat:
    win_title:                 "Diagramas de tabla de contigencia"
    heat:                      "heat"
    fluc:                      "burbuja"
gui_window::r_plot_opt::cod_mat:
    win_title:                 "Configurar: Diagramas de tabla de contigencia"
    cellnote:                  "Mostrar porcentajes"
    dendro_c:                  "Códigos de cluster"
    dendro_v:                  "Variables de cluster o Encabezados"
    bubble_size:               "Tamaño de burbujas: "
    plot_size_heat:            "Tamaño de diagrama, Alto:"
    plot_size_mapw:            "Tamaño de diagrama, Ancho:"
    plot_size_maph:            "  altura:"
    bubble_shape:              "Forma de las burbujas: "
    square:                    "cuadrado"
    circle:                    "circulo"
    common:                    "ajustes generales"
    select_1:                  "Seleccione al menos 1 código"
    color_rsd:                 "Visualizar los residuos estandarizados por color"
gui_window::r_plot::cod_mat_line:
    win_title:                 "Gráfico de línea"
gui_window::r_plot_opt::cod_mat_line:
    win_title:                 "Configurar: Gráfico de línea"
