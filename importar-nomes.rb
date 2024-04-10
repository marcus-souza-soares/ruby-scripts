require 'csv'
require 'net/http'
require 'json'

class ImportarNomes
  def initialize
    puts "Digite a série: "
    @serie = gets.chomp
    @token = File.read('token').strip
  end

  def call
    argumentos_de_periodo
    fetch_nomes
    salvar_nomes
  end

  private

  attr_reader :serie, :token, :idDisciplina, :idTurma, :trimestre, :data

  # MUDAR DE ACORDO COM A TURMA/TRIMESTRE/DISCIPLINA
  def argumentos_de_periodo
    @idDisciplina = "43"
    @idTurma = "158"
    @trimestre = "28"
  end

  def fetch_nomes
    url = URI.parse("https://evolucao.mgestor.com/crud/api/avaliacao/getAlunoNota/#{idTurma}/#{idDisciplina}/#{trimestre}")
    request = Net::HTTP::Get.new(url)
    request['Content-Type'] = "application/json"
    request['Authorization'] = "#{token}"

    response = Net::HTTP.start(url.host, url.port, use_ssl: true) do |http|
      http.request(request)
    end
    @data = JSON.parse(response.body)
    puts data.inspect
    data
  end

  def salvar_nomes
    dados = data["data"].map { |pessoa| { id: pessoa['idPessoa'], nome: pessoa['pessoa'] } }
    dados_add = data["data"][0].slice('idDisciplina', 'idturma', 'unidade', 'idAvaliacao')
    CSV.open("#{serie}.csv", "a") do |csv|
      csv << %w[ID_TURMA ID_PROVA ID_TRIMESTRE]
      csv << [dados_add["idturma"], dados_add["idAvaliacao"], dados_add["unidade"]]
    end

    CSV.open("#{serie}.csv", "a") do |csv|
      csv << %w[NOMES ID NOTAS]
    end

    dados.each do |pessoa|
      CSV.open("#{serie}.csv", "a") do |csv|
        csv << [pessoa[:nome], pessoa[:id]]
      end
    end
  end
end


ImportarNomes.new.call
