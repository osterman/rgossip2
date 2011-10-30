require 'mutex_m'
require 'openssl'

module RGossip2

  #
  # class NodeList
  # Nodeのコンテナ
  #
  # +------------+           +------------+        +--------+
  # |  Gossiper  |<>---+---+ |  NodeList  |<>-----+|  Node  |
  # +------------+     |     +------------+        +--------+
  # +------------+     |
  # |  Receiver  |<>---+
  # +------------+
  #
  class NodeList < Array
    include Mutex_m

    attr_writer :context

    # クラスの生成・初期化はContextクラスからのみ行う
    def initialize(ary = [])
      super(ary)
    end

    # 指定したNode以外のNodeをリストからランダムに選択する
    def choose_except(node)
      node_list = self.select {|i| i.address != node.address }
      node_list.empty? ? nil : node_list[rand(node_list.size)]
    end

    # ノード情報をいくつかの塊にごとにシリアライズする
    def serialize
      chunks = []
      nodes = []
      datasum = ''

      # バッファサイズ
      bufsiz = @context.buffer_size - @context.digest_length

      # Nodeはランダムな順序に変換
      self.sort_by { rand }.each do |node|
        # 長さを知るためにシリアライズ
        packed = node.serialize

        # シリアライズしてバッファサイズ以下ならチャンクに追加
        if (datasum + packed).length <= bufsiz
          nodes << node
          datasum << packed
        else
          chunks << @context.digest_and_message(nodes).join
          nodes.clear
          datasum.replace('')

          # バッファサイズを超える場合は次のチャンクに追加
          redo
        end
      end

      # 残りのNodeをチャンクに追加
      unless nodes.empty?
        chunks << @context.digest_and_message(nodes).join
      end

      return chunks
    end # serialize

  end # Nodes

end # RGossip2
