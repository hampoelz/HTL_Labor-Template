@default_files = ('main.tex');

$pdf_mode = 4;

$emulate_aux = 1;
$out_dir = './out';

set_tex_cmds('--shell-escape');

add_cus_dep('sage', 'sout', 0, 'makesout');
$hash_calc_ignore_pattern{'sage'} = '^( _st_.goboom| ?_st_.current_tex_line|print .SageT)';
sub makesout {
   system( "cd ./out/ && sage \"../$_[0].sage\"" );
}