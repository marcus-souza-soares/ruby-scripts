# gem install rubyXL

require 'rubyXL'
require 'net/http'
require 'json'

class EnviarNotas
  ENDERECO = "https://evolucao.mgestor.com/crud/api/avaliacao/salvarNota".freeze

  def initialize(nota, id, params)
    @params = params
    @nota = nota
    @id = id
    @token = File.read('token').strip
  end

  def enviar_nota
    fazer_post
  end

  private

  attr_reader :params, :nota, :token, :id

  def fazer_post
    url = URI.parse(ENDERECO)
    request = Net::HTTP::Post.new(url)
    request['Content-Type'] = "application/json"
    request['Authorization'] = "#{token}"
    request.body = { idAvaliacao: params[:prova_id].to_s, idDisciplina: "43",
                     idPessoa: id.to_s, idTurma: params[:turma_id].to_s, trimestre: params[:trimestre].to_s,
                     valor: nota.to_s, valorAvaliacao: "7" }.to_json

    response = Net::HTTP.start(url.host, url.port, use_ssl: true) do |http|
      http.request(request)
    end

    if response.code.to_i == 200
      puts "Dados enviados com sucesso!"
      puts response.body
    else
      puts "Erro ao enviar os dados. Código de resposta: #{response.code}"
    end
  end
end

class LerArquivoXLSM
  def initialize
    puts "Coloque o caminho para o arquivo XLSX"
    xlsx_file_path = gets.chomp
    @workbook = RubyXL::Parser.parse(xlsx_file_path)
  end

  attr_reader :workbook

  def ler_arquivo
    puts "Digite o numero da planilha (sheet):"
    sheet = workbook[gets.chomp.to_i - 1]
    enviar_notas(sheet)
  end

  private

  def enviar_notas(sheet)
    sheet.each_with_index do |row, index|
      next if index.zero?

      if index == 1
        turma_id, prova_id, trimestre = [0, 1, 2].map { |n| row[n].is_a?(RubyXL::Cell) ? row[n].value : nil }
        @params = { turma_id: turma_id, prova_id: prova_id, trimestre: trimestre }
        next
      end

      nome, id, nota = [0, 1, 2].map { |n| row[n].is_a?(RubyXL::Cell) ? row[n].value : nil }
      next if nota.nil? || nome.nil? || id.nil?

      EnviarNotas.new(nota, id, @params).enviar_nota
      puts "Aluno: #{nome}, Nota: #{nota}"
    end
  end
end

LerArquivoXLSM.new.ler_arquivo
