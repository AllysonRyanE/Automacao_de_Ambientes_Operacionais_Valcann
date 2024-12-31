#!/bin/bash 

#O shebang acima aponta para o interpretador Bash;

root="/home/allysonryan/"
src="$root/backupsFrom"
dst="$root/backupsTo"
#Foi definida as variáveis com a root sendo 
# concatenada aos diretórios de origem e destino.

log_from="$root/backupsFrom.log" 
log_to="$root/backupsTo.log"

if [ ! -d "$dst" ]; then
    mkdir -p "$dst"
fi
#Caso o diretório de destino não exista ele será criado.
#O uso do -p assegura a criação do intermédio caso seja preciso.

limit_date=$(date -d "3 days ago" +%s)
#Essa constante será usada como critério para remoção e cópia.
#Com o -d permite-se receber uma string e trazer uma data especifica referente.
#O %s refere-se ao formato de saída.

file_processed=0
file_copied=0
file_removed=0
#Contadores setados em 0 para ao fim trazer um feedback sobre o processo.

get_metadata() {
    local file="$1"  
    #O caminho do arquivo será o parâmetro.
    local name size creation_date mod_date
    #Var locais.
    name=$(basename "$file")
    size=$(stat -c%s "$file")
    #Retorno tamanho do arquivo em bytes.
    creation_date=$(stat -c%w "$file")
    modf_date=$(stat -c%y "$file")

    metadata=("$name" "$creation_date" "$modf_date" "$size")
}

explore_directory() {
    local directory="$1"
    #Recebe o diretório que será explorado recursivamente.
    for fa_current in "$directory"/*; do 
        #1. Irá ser listado todos os arquivos detalhadamente que estão na origem neste bloco
        #fa_current a cada iteração assumirá arquivo ou subpasta do diretório
        #Isso é possivel através do curinga *.
        if [[ -d "$fa_current" ]]; then
            #Se o item atual for uma subpasta a função é novamente chamada.
            explore_directory "$fa_current"
        elif [[ -f "$fa_current" ]]; then
            #Porém se for um arquivo ele irá extrair os dados pela função get_metadata, tornando o retorno acessível.
            get_metadata "$fa_current"
            creation_timestamp=$(date -d "${metadata[1]}" +%s) 
            #É feito a conversão da data de criação para ser feita a comparação.

            echo "Nome: ${metadata[0]}, Tamanho: ${metadata[3]} bytes, Criado em: ${metadata[1]}, Modificado em: ${metadata[2]}" >>"$log_from"
            ((file_processed++))
            #2. Então, salva-se no arquivo 'backupsFrom.log' as informações conforme os valores armazenados no array metadata.
            if [[ $creation_timestamp -lt $limit_date ]]; then
                rm "$fa_current"
                ((file_removed++))
                #3. Apesar de registrar, será removido os mais antigos (respeitando o limite de 3 dias dado).
            else
                destination="$dst/$name" #Destino das cópias
                cp --preserve=timestamps "$fa_current" "$destination"
                ((file_copied++))
                #4. Mas as cópias feitas no destino serão apenas daqueles arquivos mais recentes
                #preservando os metadados.
                echo "Backup do arquivo feito em $(date):" >>"$log_to"
                echo "Nome: ${metadata[0]}, Tamanho: ${metadata[3]} bytes, Criado em: ${metadata[1]}, Modificado em: ${metadata[2]}" >>"$log_to"
                echo "Copiado para: $destination, Original no: $fa_current" >>"$log_to"
                echo "-----------------------------------" >>"$log_to"
                #5. Por fim, na mesmo condicional (arquivos mais recentes), ou seja, tendo sido o arquivo parte do backup, 
                #será registrado em um 'log' para indicar que ele integrou esse processo de cópia.
            fi
        fi
    done
}
explore_directory "$src"

# Exibe o resumo do backup
echo "Backup concluído:"
echo "$file_processed arquivos foram processados."
echo "$file_removed arquivos foram removidos conforme as configurações."
echo "$file_copied arquivos foram copiados conforme as configurações."
