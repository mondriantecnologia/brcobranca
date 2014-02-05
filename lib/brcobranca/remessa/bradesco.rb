module Brcobranca
  module Remessa
    class Bradesco < Base
      
      def parametros
        Parametro.find 1
      end

      def num_sequencia
        1
      end

      def gerar_arquivo
        @arquivo = File.open(self.caminho_arquivo, "w")
        
        primeira_linha = self.cabecalho_generico
        @arquivo.write(primeira_linha)
        
        if self.objeto.class == PagamentoEstorno
          numero_de_registros = self.corpo_pagamento_estorno
          rodape = self.rodape_pagamento_estorno(numero_de_registros)
          @arquivo.write(rodape)
        end
        
        @arquivo.close

        comando = "sed -i 's/$/\\r/' #{nome_arquivo}"    
        system(comando)
      end
      
      def cabecalho_generico
        primeira_linha =  "0" #001 A 001 - Identificação do Registro - 001 -Obrigatório – fixo “zero”(0)
        primeira_linha << self.parametros.codigo_de_comunicacao.to_s.rjust(8,'0') # 002 A 009 - Código de Comunicação - 008 
        primeira_linha << '2' #010 A 010 -  Tipo de Inscrição da Empresa Pagadora - 1 = CPF / 2 = CNPJ / 3= OUTROS
        primeira_linha << self.parametros.cnpj_cedente.rjust(15,'0') #011 A 025 - CNPJ/CPF Base da Empresa Pagadora
        primeira_linha << I18n.transliterate(self.parametros.cedente)[0,40].ljust(40," ").upcase # 26 a 65 nome da empresa      
        primeira_linha << '20' #066 A 067 Tipo de Serviço Fixo “20”
        primeira_linha << '1' #068 A 068 Código de origem do arquivo Fixo “1”
        primeira_linha << self.parametros.sequencial_arquivo_cobranca.to_s.rjust(5,"0")   # 069 a 073 numero sequencial de remessa
        primeira_linha << '00000' #074 A 078 - Número do retorno Campo válido somente para o arquivo retorno – fixo zeros 
        primeira_linha << Time.now.strftime('%Y%m%d').to_s.rjust(8,"0") # 079 a 086 data de gravaçao do arquivo 
        primeira_linha << Time.now.strftime('%H%M%S').to_s.rjust(6,"0") #087 A 092 -hora da gravacao do arquivo
        primeira_linha << ''.ljust(5,' ') #093 A 097 -  brancos
        primeira_linha << ''.ljust(3,' ') #098 A 100 -  brancos
        primeira_linha << ''.ljust(5,' ') #101 A 105 -  brancos
        primeira_linha << '0' #106 A 106 - Tipo de processamento - Preencher com 0
        primeira_linha << ''.ljust(74,' ') #107 A 180 - Reservado a empresa preencher com brancos
        primeira_linha << ''.ljust(80,' ') #181 A 260 - Reservado ao banco preencher com brancos
        primeira_linha << ''.ljust(217,' ') #361 A 477 - Reservado ao banco preencher com brancos
        primeira_linha << self.parametros.numero_da_lista_de_debito.to_s.rjust(9,'0') #478 A 486 - Numero da lista de debito
        primeira_linha << ''.ljust(8,' ') #487 A 494 - Reservado ao banco preencher com brancos
        primeira_linha << num_sequencia.to_s.rjust(6,"0") # 495 a 500 numero sequencial do registro de um em um 
        primeira_linha << "\n"
        self.parametros.sequencial_arquivo_cobranca += 1
        self.parametros.numero_da_lista_de_debito += 1
        self.parametros.save 
        return primeira_linha
      end
      
      def corpo_pagamento_estorno
        numero_de_registros = self.num_sequencia
        self.objeto.ressarcimentos.each do |ressarcimento|
          if ressarcimento.valor >= 0.01
            numero_de_registros += 1
            informacoes_complementares = (ressarcimento.cod_banco == '237' ? ''.ljust(40,' ') : "C000000010#{ressarcimento.tipo_conta}".ljust(40,' ') )
            ## trata formatacao do cpf e cnpj para arquivo
            vcpf = ressarcimento.cpf_cnpj_favorecido.gsub(/[^0-9]/,'')
            if vcpf.size == 11
              vcpf = vcpf[0,9] + '0000' + vcpf[9,2]
            end   
            linha = "1"
            linha << ressarcimento.tipo_inscricao.to_s # 002 A 002 - Tipo de inscricao do Fornecedor - 1- CPF, 2- CNPJ, 3-OUtros
            linha << vcpf.rjust(15,'0') #003 A 017 - CPF/CNPJ fornecedor
            linha << I18n.transliterate(ressarcimento.favorecido)[0,30].gsub('º',' ').gsub('°',' ').upcase.ljust(30) #018 A 047 - Nome do fornecedor
            linha << I18n.transliterate(ressarcimento.endereco)[0,40].gsub('º',' ').gsub('°',' ').upcase.ljust(40,' ') # 048 A 087 Endereco do fornecedor
            linha << ressarcimento.cep #088 A 095 -  Cep do fornecedor
            linha << ressarcimento.cod_banco.rjust(3,'0') #096 A 098 - Codigo do banco do fornecedor
            linha << ressarcimento.agencia.rjust(5,'0') # 099 A 103 - Codigo da agencia do fornecedor
            linha << ressarcimento.digito_agencia.ljust(1,' ') # 104 A 104 - digito da agencia do fornecedor
            linha << ressarcimento.conta_corrente.rjust(13,'0') # 105 A 117 - conta ocrrente do fornecedor
            linha << ressarcimento.digito_conta.ljust(2,' ') #118 A 119 - digito da conta corrente do fornecedor
            linha << ressarcimento.numero_pagamento.ljust(16,' ') #120 A 135 - Número do Pagamento.
            linha << '000' #136 A 138 - Carteira - fixo 000
            linha << ''.rjust(12,'0') #139 A 150 - Nosso numero - fixo 0
            linha << ''.rjust(15,'0') #151 A 165 - Seu numero - fixo 0
            linha << Date.today.strftime('%Y%m%d').rjust(8,'0') #166 A 173 # data de vencimento
            linha << ''.rjust(8,'0') #174 A 181 # data de emissao - fixo 0
            linha << ''.rjust(8,'0') #182 A 189 # data limite para desconto - fixo 0
            linha << '0' #190 A 190 - Fixo 0
            linha << '0'.rjust(4,'0') #191 A 194 - Fator de vencimento - fixo 0
            linha << '0'.rjust(10,'0') #195 A 204 - Valor do Documento - fixo 0
            linha << ressarcimento.valor.contabil.gsub('.','').gsub(',','').rjust(15,'0') # 205 A 219 # valor do pagamento
            linha << '0'.rjust(15,'0') #220 A 234 - Valor do desconto - fixo 0
            linha << '0'.rjust(15,'0') #235 A 249 - Valor do acrescimo - fixo 0 
            linha << '05' #250 A 251 - Tipo de documento - 05 = OUTROS
            linha << '0'.rjust(10,'0') #252 A 261 - Numero nota fiscal - fixo 0
            linha << '  ' #262 A 263 - serie do documento - opicional 
            linha << (ressarcimento.cod_banco == '237' ? '05' : '03' ) #264 A 265 - modalidade de pagamento - 01 = transf, 03 = doc
            linha << Date.today.strftime('%Y%m%d').rjust(8,"0") #266 A 273 # data para efetivacao do pagmento
            linha << ''.ljust(3,' ') # 274 A 276 - Moeda - Fixo Branco
            linha << '01' # 277 a 278 - Situação do Agendamento - Fixo 01
            linha << ''.ljust(10,' ') #279 A 288 - Informacao de retorno - fixo branco
            linha << '0' # 289 A 289 - Tipo de movimento - 0 = inclusao
            linha << '25' # 290 A 291 - Codigo do movimento - 25 = autoriza agendamento
            linha << ''.ljust(4,' ') # 292 A 295 - Horario para consulta de saldo - fixo branco
            linha << ''.ljust(15,' ')# 296 A 310 - Saldo disponivel - fixo branco
            linha << ''.ljust(15,' ')# 311 A 325 - Valor da taxa pre-funding - fixo branco  
            linha << ''.ljust(6,' ') # 326 A 331 - fixo brancos
            linha << ''.ljust(40,' ') # 332 A 371 - Sacador avalista  somente para titulos em cobranca - fixo brancos
            linha << ' '#372 A 372 - Fixo Branco
            linha << ' '#373 A 373 - Nivel da informacao do retorno - Fixo Branco
            linha << informacoes_complementares #374 a 413 # informacoes complementares
            linha << '00' #414 A 415 - codigo de area na empresa - opcional
            linha << ''.ljust(35,' ') # 416 A 450 - Para uso da empresa - fixo branco
            linha << ''.ljust(22,' ') # 451 A 472 - Fixo Brancos
            linha << ressarcimento.id.to_s.rjust(5,'0')   #473 A 477 - Codigo de lancamento
            linha << ' ' # 478 A 478 reserva - fixo branco
            linha << ressarcimento.tipo_conta.to_s #479 A 479 - Tipo de conta do fornecedor - 1 = conta corrente, 2= conta poupanca
            linha << self.parametros.conta.rjust(7,'0') #480 A 486 - Conta complementar - Fixo 0
            linha << ''.ljust(8,' ') # 487 A 494 - fixo branco
            linha << numero_de_registros.to_s.rjust(6,'0')  # 495 a 500 num sequencial do registro
            linha << "\n"
            @arquivo.write(linha)
          end
        end
        return numero_de_registros
      end
    
      def rodape_pagamento_estorno(numero_de_registros)
        numero_de_registros += 1
        linha_rodape = '9' # 001 A 001 - fixo 9
        linha_rodape << numero_de_registros.to_s.rjust(6,'0') # 002 A 007 - quantidade de registros incluindo o header e o proprio trailer
        linha_rodape << self.objeto.valor.contabil.gsub('.','').gsub(',','').rjust(17,"0") # 008 A 024 - Valor dos registros
        linha_rodape << ''.ljust(470,' ') # 025 A 494 # fixo branco
        linha_rodape << numero_de_registros.to_s.rjust(6,"0")  # 495 a 500 num sequencial do registro
        linha_rodape << "\n"
        return linha_rodape        
      end
    
    end
  end
end
