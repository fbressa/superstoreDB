#Descição

O arquivo sql no repositório contém uma abreviação da base de dados utilizada para o DER e o DLD. 
Esta base de dados está diponível [aqui](https://www.kaggle.com/datasets/vivek468/superstore-dataset-final)
Vale ressaltar que o dataset original do Superstore, disponível publicamente no Kaggle, encontra-se em formato desnormalizado, 
ou seja, todas as informações de clientes, produtos, pedidos e itens estão consolidadas em uma única tabela CSV. 
Para torná-lo compatível com um Sistema Gerenciador de Banco de Dados Relacional (SGBDR), foi necessário realizar um processo de normalização, 
separando os dados em quatro entidades principais: Clientes, Produtos, Pedidos e Itens_Pedido. 
Esse processo garante a eliminação de redundâncias, melhora a integridade referencial e facilita a realização de consultas analíticas. 
Assim, cada atributo do arquivo bruto foi mapeado para a entidade correspondente no modelo relacional, preservando a fidelidade dos dados originais e permitindo uma implementação consistente no MySQL.
