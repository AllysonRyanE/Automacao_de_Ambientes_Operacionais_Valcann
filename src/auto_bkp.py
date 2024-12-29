import os
import datetime
import shutil

"""A função abaixo ela utiliza-se de metódos da biblioteca 'os' para extrair os metadados de um arquivo especificado através do caminho."""


def get_metadate(path_local):
    stts = os.stat(path_local)
    #O metódo stat executa uma extração de uma série de valores e retorna numa grande tupla
    name = os.path.basename(path_local)  #Extrai o nome do arquivo
    creation_data = datetime.datetime.fromtimestamp(stts.st_ctime)
    #Iremos armazenar esses valores convertendo para datetime
    modf_data = datetime.datetime.fromtimestamp(stts.st_mtime)
    return name, creation_data, modf_data, stts.st_size


"""Definimos as variáveis alvo do processo, ou seja a origem, o destino e a raiz."""
root = '/home/valcann/'
#Caso queira testar localmente com os diretórios dados, talvez seja preciso substituir o valor por apenas 'home/valcann/
src = root + 'backupsFrom'
dst = root + 'backupsTo'

log_from = os.path.join(root, 'backupsFrom.log')
log_to = os.path.join(root, 'backupsTo.log')

limit_data = datetime.datetime.now() - datetime.timedelta(days=3)
#Essa constante será definida antes do processo, sendo utilizada como critério para remoções e cópias.

file_processed = 0
file_coppied = 0
file_removed = 0

with open(log_from, 'w') as reg_from:  #1. Irei listar todos os arquivos detalhadamente que estão na origem.
    for path, directories, files in os.walk(src):
        """Retorna uma 3-pla com o primeiro valor sendo o caminho do arquivo, o segundo sendo os diretórios presentes e o 
        último uma lista com os arquivos."""
        for f_current in files:  #Vamos explorar essa lista.
            absolute_path = os.path.join(path, f_current)
            destination_path = os.path.join(dst, f_current)
            metadate_file = get_metadate(absolute_path)  #Metadados.
            reg_from.write(f"Nome: {metadate_file[0]}, Tamanho: {metadate_file[3]} bytes, Criado em: {metadate_file[1]}, Modificado em: {metadate_file[2]}\n")
            file_processed += 1
            """2. Acima salvo no arquivo aberto que apesar doa lias como reg_from trata-se do recém-criado 'backupsFrom.log', 
            faço escrita nele conforme os valores armazenados na tupla 'metadata_file' que contém o retorno da função."""
            if metadate_file[1] < limit_data:
                os.remove(absolute_path)  #3. Apesar de registrar irei remover os mais antigos (respeitando o limite de 3 dias dado).
                file_removed += 1
            else:  #4. Mas irei fazer cópias no destino apenas daqueles mais recentes.
                shutil.copy2(absolute_path, destination_path)
                file_coppied += 1
                with open(log_to, 'a') as reg_to:
                    """5. Por fim, na mesmo condicional (arquivos mais recentes), ou seja, tendo sido ele parte do backup, 
                    irei registar isso em um 'log' para indicar que ele integrou esse processo de cópia."""
                    reg_to.write(f"Backup do arquivo feito em {datetime.datetime.now()}:\n"
                                 f"Nome: {metadate_file[0]}, Tamanho: {metadate_file[3]} bytes, "
                                 f"Criado em: {metadate_file[1]}, Modificado em: {metadate_file[2]}\n"
                                 f"Copiado para: {destination_path}, Original no: {absolute_path}\n" + "-" * 35 + "\n")
print(f"Backup concluido:\n {file_processed} foram processados.\n"
      f"{file_removed} foram removidos conforme as configurações.\n"
      f"{file_coppied} foram copiados conforme as configurações.")
