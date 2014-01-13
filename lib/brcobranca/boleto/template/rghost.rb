# -*- encoding: utf-8 -*-

begin
  require 'rghost'
rescue LoadError
  require 'rubygems' unless ENV['NO_RUBYGEMS']
  gem 'rghost'
  require 'rghost'
end

begin
  require 'rghost_barcode'
rescue LoadError
  require 'rubygems' unless ENV['NO_RUBYGEMS']
  gem 'rghost_barcode'
  require 'rghost_barcode'
end

module Brcobranca
  module Boleto
    module Template
      # Templates para usar com Rghost
      module Rghost
        extend self
        include RGhost unless self.include?(RGhost)
        RGhost::Config::GS[:external_encoding] = Brcobranca.configuration.external_encoding

        # Gera o boleto em usando o formato desejado [:pdf, :jpg, :tif, :png, :ps, :laserjet, ... etc]
        #
        # @return [Stream]
        # @see http://wiki.github.com/shairontoledo/rghost/supported-devices-drivers-and-formats Veja mais formatos na documentação do rghost.
        # @see Rghost#modelo_generico Recebe os mesmos parâmetros do Rghost#modelo_generico.
        def to(formato, options={:generico => true})
          #if options[:generico] == true
             #modelo_generico(self, options.merge!({:formato => formato}))
          #else
             modelo_mondrian(self, options.merge!({:formato => formato}))
          #end
        end

        # Gera o boleto em usando o formato desejado [:pdf, :jpg, :tif, :png, :ps, :laserjet, ... etc]
        #
        # @return [Stream]
        # @see http://wiki.github.com/shairontoledo/rghost/supported-devices-drivers-and-formats Veja mais formatos na documentação do rghost.
        # @see Rghost#modelo_generico Recebe os mesmos parâmetros do Rghost#modelo_generico.
        def lote(boletos, options={})
          modelo_generico_multipage(boletos, options)
        end

        #  Cria o métodos dinâmicos (to_pdf, to_gif e etc) com todos os fomátos válidos.
        #
        # @return [Stream]
        # @see Rghost#modelo_generico Recebe os mesmos parâmetros do Rghost#modelo_generico.
        # @example
        #  @boleto.to_pdf #=> boleto gerado no formato pdf
        def method_missing(m, *args)
          method = m.to_s
          if method.start_with?("to_")
            modelo_generico(self, (args.first || {}).merge!({:formato => method[3..-1]}))
          else
            super
          end
        end

        private

        # Retorna um stream pronto para gravação em arquivo.
        #
        # @return [Stream]
        # @param [Boleto] Instância de uma classe de boleto.
        # @param [Hash] options Opção para a criação do boleto.
        # @option options [Symbol] :resolucao Resolução em pixels.
        # @option options [Symbol] :formato Formato desejado [:pdf, :jpg, :tif, :png, :ps, :laserjet, ... etc]
        def modelo_generico(boleto, options={})
          doc=Document.new :paper => :A4 # 210x297

          template_path = File.join(File.dirname(__FILE__),'..','..','arquivos','templates','modelo_generico.eps')

          raise "Não foi possível encontrar o template. Verifique o caminho" unless File.exist?(template_path)

          modelo_generico_template(doc, boleto, template_path)
          modelo_generico_cabecalho(doc, boleto, {})
          modelo_generico_rodape(doc, boleto)

          #Gerando codigo de barra com rghost_barcode
          doc.barcode_interleaved2of5(boleto.codigo_barras, :width => '10.7 cm', :height => '1.2 cm', :x => '0.7 cm', :y => '5.8 cm' ) if boleto.codigo_barras

          # Gerando stream
          formato = (options.delete(:formato) || Brcobranca.configuration.formato)
          resolucao = (options.delete(:resolucao) || Brcobranca.configuration.resolucao)
          doc.render_stream(formato.to_sym, :resolution => resolucao)
        end

        # Retorna um stream pronto para gravação em arquivo.
        #
        # @return [Stream]
        # @param [Boleto] Instância de uma classe de boleto.
        # @param [Hash] options Opção para a criação do boleto.
        # @option options [Symbol] :resolucao Resolução em pixels.
        # @option options [Symbol] :formato Formato desejado [:pdf, :jpg, :tif, :png, :ps, :laserjet, ... etc]
        def modelo_mondrian(boleto, options={})
          doc=Document.new :paper => :A4 # 210x297

          template_path = File.join(File.dirname(__FILE__),'..','..','arquivos','templates','modelo_mondrian.eps')

          raise "Não foi possível encontrar o template. Verifique o caminho" unless File.exist?(template_path)

          opts = {:logo => 60}
          modelo_mondrian_template(doc, boleto, template_path)
          modelo_mondrian_cabecalho(doc, boleto, opts)
          modelo_mondrian_rodape(doc, boleto, opts) 

          #Gerando codigo de barra com rghost_barcode
          doc.barcode_interleaved2of5(boleto.codigo_barras, :width => '12.7 cm', :height => '1.6 cm', :x => '0.7 cm', :y => '1.8 cm' ) if boleto.codigo_barras

          # Gerando stream
          formato = (options.delete(:formato) || Brcobranca.configuration.formato)
          resolucao = (options.delete(:resolucao) || Brcobranca.configuration.resolucao)
          doc.render_stream(formato.to_sym, :resolution => resolucao)
        end



        # Retorna um stream para multiplos boletos pronto para gravação em arquivo.
        #
        # @return [Stream]
        # @param [Array] Instâncias de classes de boleto.
        # @param [Hash] options Opção para a criação do boleto.
        # @option options [Symbol] :resolucao Resolução em pixels.
        # @option options [Symbol] :formato Formato desejado [:pdf, :jpg, :tif, :png, :ps, :laserjet, ... etc]
        def modelo_generico_multipage(boletos, options={})
          doc=Document.new :paper => :A4, :margin => [0.5, 2, 0.5, 2] # 210x297

          template_path = File.join(File.dirname(__FILE__),'..','..','arquivos','templates','modelo_generico.eps')

          raise "Não foi possível encontrar o template. Verifique o caminho" unless File.exist?(template_path)

          boletos.each_with_index do |boleto, index|
            modelo_generico_template(doc, boleto, template_path)
            modelo_generico_cabecalho(doc, boleto)
            modelo_generico_rodape(doc, boleto)

            #Gerando codigo de barra com rghost_barcode
            doc.barcode_interleaved2of5(boleto.codigo_barras, :width => '10.3 cm', :height => '1.3 cm', :x => '0.7 cm', :y => '1.8 cm' ) if boleto.codigo_barras
            #Cria nova página se não for o último boleto
            doc.next_page unless index == boletos.length-1

          end
          # Gerando stream
          formato = (options.delete(:formato) || Brcobranca.configuration.formato)
          resolucao = (options.delete(:resolucao) || Brcobranca.configuration.resolucao)
          doc.render_stream(formato.to_sym, :resolution => resolucao)
        end

        # Define o template a ser usado no boleto
        def modelo_mondrian_template(doc, boleto, template_path)
          doc.define_template(:template, template_path, :x => '0.3 cm', :y => "-4 cm")
          doc.use_template :template

          doc.define_tags do
            tag :grande,  :name => 'NimbusSanL-Bold', :size => 13
            tag :gigante, :name => 'NimbusSanL-Bold', :size => 16
            tag :negrito, :name => 'NimbusSanL-Bold'
          end
        end

        # Monta o cabeçalho do layout do boleto
        def modelo_mondrian_cabecalho(doc, boleto, opts = {:logo => 80})
          #doc.use_tag :negrito
          instrucoes = [
            "Instruções de Impressão",
            "- Imprima em impressora jato de tinta (ink jet) ou laser em qualidade normal ou alta (Não use modo econômico).",
            "- Utilize folha A4 (210 x 297 mm) ou Carta (216 x 279 mm) e margens mínimas à esquerda e à direita do formulário.",
            "- Corte na linha indicada. Não rasure, risque, fure ou dobre a região onde se encontra o código de barras.",
            "- Caso não apareça o código de barras no final, clique em F5 para atualizar esta tela.",
            "- Caso tenha problemas ao imprimir, copie a sequencia numérica abaixo e pague no caixa eletrônico ou internet banking:"
          ]

          doc.text_in :write => instrucoes[0], :x => 9, :y => 29
          doc.text_in :write => instrucoes[1], :x => 1, :y => 28.5
          doc.text_in :write => instrucoes[2], :x => 1, :y => 28
          doc.text_in :write => instrucoes[3], :x => 1, :y => 27.5
          doc.text_in :write => instrucoes[4], :x => 1, :y => 27
          doc.text_in :write => instrucoes[5], :x => 1, :y => 26.5

          #Linha Digitável: 23792.21407 60900.090683 62002.710507 8 59430000006930
          #Valor: R$ 69,30
          # ORIGEM: CAPITAL
          # PLACA: HXH0000

          #INICIO Primeira parte do BOLETO
          # LOGOTIPO do BANCO
          doc.image(boleto.logotipo, :x => '0.5 cm', :y => "20.45 cm", :zoom => opts[:logo])
          # Dados
          doc.text_in :write => "#{boleto.banco}-#{boleto.banco_dv}", :x => '5.14 cm', :y => "20.35 cm", :tag => :gigante
          doc.text_in :write => boleto.codigo_barras.linha_digitavel, :x => '7.5 cm', :y => "20.35 cm", :tag => :grande
          # Linha 1
          doc.text_area boleto.cedente, :width => "8.5 cm",   :x => "0.7 cm",  :y => "19.5 cm"
          doc.text_in :write => boleto.agencia_conta_boleto,  :x => "11 cm",   :y => "19.5 cm"
          doc.text_in :write => boleto.especie,               :x => "14.2 cm", :y => "19.5 cm"
          doc.text_in :write => boleto.quantidade,            :x => "15.7 cm", :y => "19.5 cm"
          doc.text_in :write => boleto.nosso_numero_boleto,   :x => "18 cm",   :y => "19.5 cm"

          # Linha 2
          doc.text_in :write => boleto.numero_documento,                          :x => "0.7 cm",   :y => "18.25 cm"
          doc.text_in :write => "#{boleto.documento_cedente.formata_documento}",  :x => "7 cm",     :y => "18.25 cm"
          doc.text_in :write => boleto.data_vencimento.to_s_br,                   :x => "12 cm",    :y => "18.25 cm"
          doc.text_in :write => boleto.valor_documento.to_currency,               :x => "19.68 cm", :y => "18.25 cm"

          doc.text_in :write => "#{boleto.sacado_endereco}", :x => "1.4 cm" , :y => "16.9 cm"
          doc.text_in :write => "#{boleto.sacado} - #{boleto.sacado_documento.formata_documento}", :x => "1.4 cm" , :y => "16.6 cm"
          #FIM Primeira parte do BOLETO
        end

        # Monta o corpo e rodapé do layout do boleto
        def modelo_mondrian_rodape(doc, boleto, opts = {:logo => 80})
          #INICIO Segunda parte do BOLETO BB
          # LOGOTIPO do BANCO
          doc.image(boleto.logotipo, :x => "0.5 cm", :y => "13 cm", :zoom => opts[:logo])
          doc.text_in :write => "#{boleto.banco}-#{boleto.banco_dv}", :x => "5.14 cm" , :y => "12.94 cm", :tag => :gigante
          doc.text_in :write => boleto.codigo_barras.linha_digitavel, :x => "7.5 cm" , :y =>  "12.94 cm", :tag => :grande

          # Linha 1
          doc.text_in :write => boleto.local_pagamento,            :x => "0.7 cm",  :y => "12 cm"
          doc.text_in :write => boleto.data_vencimento.to_s_br,    :x => "18.97 cm",:y => "12 cm"   if boleto.data_vencimento
          # Linha 2
          doc.text_in :write => boleto.cedente,                    :x => "0.7 cm",  :y => "11.2 cm"
          doc.text_in :write => boleto.agencia_conta_boleto,       :x => "17.9 cm", :y => "11.2 cm"
          # Linha 3
          doc.text_in :write => boleto.data_documento.to_s_br,     :x => "0.7 cm",  :y => "10.4 cm" if boleto.data_documento
          doc.text_in :write => boleto.numero_documento,           :x => "4.2 cm",  :y => "10.4 cm"
          doc.text_in :write => boleto.especie_documento,          :x => "10 cm",   :y => "10.4 cm"
          doc.text_in :write => boleto.aceite,                     :x => "11.7 cm", :y => "10.4 cm"
          doc.text_in :write => boleto.data_processamento.to_s_br, :x => "13 cm",   :y => "10.4 cm" if boleto.data_processamento
          doc.text_in :write => boleto.nosso_numero_boleto,        :x => "18 cm" ,  :y => "10.4 cm"
          #Linha 4
          doc.text_in :write => boleto.carteira,   :x => "4.4 cm", :y => "9.58 cm"
          doc.text_in :write => boleto.especie,    :x => "6.4 cm", :y => "9.58 cm"
          doc.text_in :write => boleto.quantidade, :x => "8 cm",   :y => "9.58 cm"
          # doc.moveto :x => "11 cm" , :y => "13.5 cm"
          # doc.show boleto.valor.to_currency

          doc.show boleto.valor_documento.to_currency, :x => "19.7 cm" , :y => "9.5 cm"

          doc.text_in :write => boleto.instrucao1, :x => "0.7 cm" , :y => "8.7 cm"
          doc.text_in :write => boleto.instrucao2, :x => "0.7 cm" , :y => "8.3 cm"
          doc.text_in :write => boleto.instrucao3, :x => "0.7 cm" , :y => "7.9 cm"
          doc.text_in :write => boleto.instrucao4, :x => "0.7 cm" , :y => "7.5 cm"
          doc.text_in :write => boleto.instrucao5, :x => "0.7 cm" , :y => "7.1 cm"
          doc.text_in :write => boleto.instrucao6, :x => "0.7 cm" , :y => "6.7 cm"
          doc.text_in :write => "#{boleto.sacado} - #{boleto.sacado_documento.formata_documento}", :x => "1.2 cm" , :y => "4.8 cm" if boleto.sacado && boleto.sacado_documento
          doc.text_in :write => "#{boleto.sacado_endereco}", :x => "1.2 cm" , :y => "4.4 cm"
          #FIM Segunda parte do BOLETO
        end
      end #Base
    end
  end
end

