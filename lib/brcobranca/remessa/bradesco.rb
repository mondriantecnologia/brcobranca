require 'parseline'
module Brcobranca
  module Remessa
    class Bradesco < Base
      
      def gerar_arquivo
        
        arquivo = File.open(caminho_arquivo, "w")
        s = 1
        # aki entra o cabeçalho
        @config = Parametro.find(:first)
        linha_cab = self.monta_cabecalho(s)
        arq.write(linha_cab)
        # fim cabeçalho
        for item in self.ressarcimentos
          if item.valor >= 0.01
            s += 1
            linha = self.monta_linha_remessa(item,s)
            arq.write(linha)
          end
        end
        # Aqui entra o rodapé
        linha_tra = self.monta_trailer(s)
        arq.write(linha_tra)     
        arq.close
        #usa o sed pra colocar as quebras de linha windows
        comando = "sed -i 's/$/\\r/' #{nome_arquivo}"    
        system(comando)
        #coloca o arquivo no registro
        self.arquivo = "/estornos/cecaf/#{base_arquivo}"
        self.save
      end
      
      
    end
  end
end
