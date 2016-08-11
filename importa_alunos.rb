#!/usr/bin/ruby

require 'net/http'        #classes para conexao e requisicao 
require 'json'            #classes para o parse do resultado da requisicao
require 'highline/import' #classes para entrada pelo terminal (usuario, senha, etc) 
require 'httparty'

#valores padrao
ip_da_maquina = "10.100.20.9"
usuario = "admin"
senha = "admin"
arquivo = "enrollments.csv"
acao = "1"

pedir_do_terminal = true  # colocar false se for usar apenas os valores padrao

#apenas usuarios deste grupo serao atualizados
nome_do_grupo = "Aluno"

#deixar atualizar usuarios que, alem de estarem no nome_grupo, tambem possam estar no grupo Padrao
permitir_grupo_padrao = true 
id_do_grupo_padrao = 1

#OBS:
# se permitir_grupo_padrao for falso, apenas usuario que estejam somente em 'nome_do_grupo' serao alterados.

# se permitir_grupo_padrao for verdadeiro, apenas usuarios que estejam em 'nome_do_grupo' serao alterados, mas
# se estes mesmos usuarios tambem estiverem no grupo Padrao, eles ainda assim serao alterados

if pedir_do_terminal

  puts "Entre com os dados solicitados, ou apenas <Enter> para manter o padrao:"

  ip_da_maquina_terminal = ask("IP da maquina (padrao "+ip_da_maquina+"):  ") { |q| q.echo = true }
  usuario_terminal = ask("Usuario (padrao "+usuario+"):  ") { |q| q.echo = true }
  senha_terminal   = ask("Senha   (padrao "+senha+"):  ") { |q| q.echo = "*" }
  arquivo_terminal = ask("Caminho e nome do arquivo csv (padrao "+arquivo+"):  ") { |q| q.echo = true }

  puts "Escolha a acao a ser feita:"
  puts "1 - Apenas criar na maquina as contas existentes no arquivo csv"
  puts "2 - Apenas excluir da maquina as contas existentes no arquivo csv"
  puts "3 - Sincronizar, deixando a maquina com as mesmas contas do arquivo csv"
  puts "Obs: Sao criadas, excluidas ou sincronizadas apenas as contas do grupo " + nome_do_grupo

  acao_terminal = ask("Acao (padrao "+acao+"):  ") { |q| q.echo = true }

  if ip_da_maquina_terminal != ""
    ip_da_maquina = ip_da_maquina_terminal 
  end

  if usuario_terminal != ""
    usuario = usuario_terminal
  end

  if senha_terminal != ""
    senha = senha_terminal
  end

  if arquivo_terminal != ""
    arquivo = arquivo_terminal
  end

  if acao_terminal != ""
    acao = acao_terminal
  end

end #pedir do terminal


if not ['1', '2', '3'].include?(acao)  

  puts "Acao " + acao  + " nao e valida. Escolha 1, 2 ou 3" 
  exit

end

#puts "_" + ip_da_maquina + "_"
#puts "_" + usuario       + "_"
#puts "_" + senha         + "_"
#puts "_" + arquivo       + "_"
#puts "_" + acao          + "_"

sessao = ""

#tentar conectar a maquina, crando uma sessao:
uri = URI('http://' + ip_da_maquina + '/login.fcgi')
resposta = Net::HTTP.post_form(uri, 'login' => usuario, 'password' => senha)


#fazer o parse dos campos da resposta
campos_resposta = JSON.parse(resposta.body)

if campos_resposta.key?("session")
  #conseguiu criar a sessao 
  sessao = campos_resposta["session"]
else
  #nao conseguiu criar a sessao, imprimir a resposta com o possivel erro
  puts "Nao foi possivel conectar a maquina "+ip_da_maquina+" com o usuario "+usuario+" e criar a sessao."
  puts resposta.body
  exit
end

puts sessao


#ler as entradas do arquivo csv para um hash matricula=>nome
hash_arquivo_csv = {}

#File.open(arquivo, :encoding => 'iso-8859-1').each do |linha|
File.open(arquivo).each do |linha|

  #tirar uma possivel quebra de linha e espacos vazios
  linha.chomp!.strip!

  #ignora alguma possivel linha vazia
  if linha == ""
    next
  end

  #print  "#{line_num += 1} #{line}"
  #puts "_" + linha.chomp + "_"
  puts "_" + linha + "_"

 
  #puts linha.chomp.force_encoding( Encoding::ISO_8859_1).encode('UTF-8')


  #trata o encoding da string. Converte do formato ISO_8859_1 para o formato UTF-8
  linha = linha.force_encoding(Encoding::ISO_8859_1).encode('UTF-8')
  
  #puts linha.chomp
  puts "_" + linha + "_"

  campos = linha.split(",")
  
  if campos.size != 2
    puts "Erro. Uma das linhas do arquivo csv tem formato desconhecido."
    puts "linha:" + linha
    exit
  end

  nome = campos[0].strip
  cpf = campos[1].strip 

  #retirar possiveis aspas do nome, e depois remove possiveis espacos:
  #nome.tr!('"','').strip! 
  #cpf.tr!('"','').strip!
  
  nome.tr!('"','')
  nome.strip!
  
  if nome == ""
    puts "Erro. Uma das linhas do csv contem o nome vazio."
    puts "linha:" + linha
    #exit
    puts 'log'
  end

  #retirar do cpf todos os caracteres que nao sejam digitos
  cpf.tr!('^0-9','') 

  if cpf == ""
    puts "Erro. Uma das linhas do csv contem o cpf vazio ou sem digitos."
    puts "linha:" + linha
    #exit
    puts "log"
  end

  #ignorar a linha e ir para a proxima, se o nome ou o cpf forem vazios
  if nome == ""  or  cpf == ""
    next
  end

  puts "_" + nome + "_"
  puts "_" + cpf + "_"

  
  #inserir no hash, se a chave cpf nao existir
  if not hash_arquivo_csv.key?(cpf)
    hash_arquivo_csv[cpf] = nome
  else
    puts "Erro. Ha um cpf duplicado no arquivo csv."
    puts "linha:" + linha
    puts "log"
  end


  puts "-----------------------------"  

 
end


hash_arquivo_csv.to_a.each do |registro|
  puts registro[0] + "," + registro[1]
end  



=begin
#loop para testar a insercao

uri = URI('http://' + ip_da_maquina + '/create_objects.fcgi?session=' + sessao)

hash_arquivo_csv.to_a.each do |registro|
  #puts registro[0] + "," + registro[1]

  cpf = registro[0]
  nome = registro[1]

  resposta = HTTParty.post(uri,
      :body=> { :object => 'users', :values => [{:name => nome, :registration => cpf}] }.to_json,
      :headers => { 'Content-Type' => 'application/json' } )

  campos_resposta = JSON.parse(resposta.body)
  puts campos_resposta

end
=end



=begin
#loop para testar a exclusao

uri = URI('http://' + ip_da_maquina + '/destroy_objects.fcgi?session=' + sessao)

hash_arquivo_csv.to_a.each do |registro|

  cpf = registro[0]

  resposta = HTTParty.post(uri,
      :body=> { :object => 'users', :where => { :users => { :registration => cpf } } }.to_json,
      :headers => { 'Content-Type' => 'application/json' } )

  campos_resposta = JSON.parse(resposta.body)
  puts campos_resposta

end
=end



#pegar os valores da maquinaj

#pegar o código do grupo

uri = URI('http://' + ip_da_maquina + '/load_objects.fcgi?session=' + sessao)
resposta = Net::HTTP.post_form(uri, 'object' => 'groups')

#fazer o parse dos campos da resposta
campos_resposta = JSON.parse(resposta.body)

#puts campos_resposta

registros = campos_resposta["groups"]

#puts registros[3]


id_do_grupo = "vazio"

registros.each do |registro|
  puts registro
  puts registro["name"]
  puts registro["id"] 
  if registro["name"] == nome_do_grupo
    id_do_grupo = registro["id"]      
  end   
end

puts "id_do_grupo:" + id_do_grupo.to_s

if id_do_grupo.to_s == "vazio"
  puts "Erro. Nao foi possivel determinar o id do grupo " + nome_do_grupo + " a partir da maquina."
  puts "Saindo sem fazer alteracoes."
  exit
end

#pegar os usuarios

usuarios = "vazio"

uri = URI('http://' + ip_da_maquina + '/load_objects.fcgi?session=' + sessao)
resposta = Net::HTTP.post_form(uri, 'object' => 'users')

#fazer o parse dos campos da resposta
campos_resposta = JSON.parse(resposta.body)

usuarios = campos_resposta["users"]

puts usuarios

if usuarios.to_s == "vazio"
  puts "Erro. Nao foi possivel buscar os usuarios a partir da maquina."
  puts "Saindo sem fazer alteracoes."
  exit
end


#pegar a relacao user_groups

usuarios_grupos = "vazio"

uri = URI('http://' + ip_da_maquina + '/load_objects.fcgi?session=' + sessao)
#resposta = Net::HTTP.post_form(uri, 'object' => 'user_groups')


#def para_enviar_1
#{
#  object: "user_groups".to_s
#}
#end

#resposta = HTTParty.post(uri, para_enviar_1)

#resposta = HTTParty.post(uri, 
#    :body => { :object => 'user_groups'}.to_json,
#    :headers => { 'Content-Type' => 'application/json' } )


resposta = HTTParty.post(uri, 
    :body=> { :object => 'user_groups'}.to_json,
    :headers => { 'Content-Type' => 'application/json' } )


#puts resposta

#exit

#fazer o parse dos campos da resposta
campos_resposta = JSON.parse(resposta.body)

usuarios_grupos = campos_resposta["user_groups"]

puts usuarios_grupos

if usuarios_grupos.to_s == "vazio"
  puts "Erro. Nao foi possivel buscar a relacao usuarios_grupos a partir da maquina."
  puts "Saindo sem fazer alteracoes."
  exit
end


#criar o array de cpfs validos vindos da maquina:

grupos_de_cada_usuario = {}

usuarios_grupos.each do |registro|
  id_usuario = registro["user_id"]   
  id_grupo = registro["group_id"] 

  if not grupos_de_cada_usuario.key?(id_usuario)
    grupos_de_cada_usuario[id_usuario] = [id_grupo]
  else
    grupos_de_cada_usuario[id_usuario].push(id_grupo)
  end


  #if not grupos_de_cada_usuario.key 


  #grupos_de_cada_usuario[id_usuario].push(id_grupo)
end

puts grupos_de_cada_usuario

#determinar os usuarios que sejam do grupo

hash_maquina = {}

usuarios.each do |usuario|
  id_usuario = usuario["id"]

  if not grupos_de_cada_usuario.key?(id_usuario)
    #este usuario nao esta relacionado a nenhum grupo
    puts "log  usuario sem grupo"
    next
  end 

  grupos_do_usuario = grupos_de_cada_usuario[id_usuario] 
  tamanho = grupos_do_usuario.size

  if tamanho > 2
    #so permite no maximo o grupo escolhido e possivelmente o padrao
    next
  end

  if (tamanho == 2) and (not permitir_grupo_padrao)
    #caso o grupo padrao nao seja permitido, apena um grupo ,o escolhido, sera permitido
    next
  end

  if not grupos_do_usuario.include?(id_do_grupo)
    #independente de ser 1 ou 2 grupos, o grupo escolhido deve estar entre eles 
    next
  end

  if (tamanho == 2) and (not grupos_do_usuario.include?(id_do_grupo_padrao))  
    #caso sejam dois grupos, o segundo grupo deve ser o grupo padrao
    next
  end

  #usuario passou, incluir pelo cpf. 
  #E sobre possiveis duplicatas de cpf na maquina? 
  #No caso da maquina, os registros duplicados ficam num array


  cpf = usuario["registration"]

  #deixar apenas digitos no cpf
  cpf.tr!('^0-9','')
  
  #cpfs vazios nao sao considerados
  if cpf == ""
    puts "log,  conta sem cpf"
    next
  end
  
  
  if not hash_maquina.key?(cpf) 
    hash_maquina[cpf] = [usuario]
  else
    hash_maquina[cpf].push(usuario)
  end

end

puts hash_maquina



#loop para testar a insercao

uri = URI('http://' + ip_da_maquina + '/create_objects.fcgi?session=' + sessao)

hash_arquivo_csv.to_a.each do |registro|
  #puts registro[0] + "," + registro[1]

  cpf = registro[0]
  nome = registro[1]

  resposta = HTTParty.post(uri,
    :body=> { :object => 'users', :values => [{:name => nome, :registration => cpf}] }.to_json,
    :headers => { 'Content-Type' => 'application/json' } )

  campos_resposta = JSON.parse(resposta.body)
  puts campos_resposta

  puts campos_resposta["ids"][0]
 

  #inserir o usuario recem criado na tabela de relacionamento user_groups 
  id_do_usuario = campos_resposta["ids"][0] 

  resposta = HTTParty.post(uri,
    :body=> { :object => 'user_groups', :values => [{:user_id => id_do_usuario, :group_id => id_do_grupo}] }.to_json,
    :headers => { 'Content-Type' => 'application/json' } )

  campos_resposta = JSON.parse(resposta.body)
  puts campos_resposta

end

                    

#deslogar da maquina
uri = URI('http://' + ip_da_maquina + '/logout.fcgi?session=' + sessao)
resposta = Net::HTTP.post_form(uri, {})
puts resposta



