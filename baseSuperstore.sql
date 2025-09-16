
-- ===============================
-- Superstore - Base de Dados (DER/DLD do usuário)
-- SGBD: MySQL 8+
-- ===============================

-- 0) Preparação
CREATE DATABASE IF NOT EXISTS superstore_db
  DEFAULT CHARACTER SET utf8mb4
  DEFAULT COLLATE utf8mb4_0900_ai_ci;
USE superstore_db;

-- Limpeza segura (ordem por FK)
DROP TABLE IF EXISTS Itens_Pedido;
DROP TABLE IF EXISTS Pedidos;
DROP TABLE IF EXISTS Produtos;
DROP TABLE IF EXISTS Clientes;

-- 1) Tabelas
CREATE TABLE Clientes (
  id_Cliente INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  nome       VARCHAR(120)  NOT NULL,
  segmento   ENUM('Consumer','Corporate','Home Office') NOT NULL DEFAULT 'Consumer',
  regiao     VARCHAR(40)   NOT NULL,
  cidade     VARCHAR(80)   NULL,
  estado     VARCHAR(40)   NULL,
  email      VARCHAR(140)  NULL,
  UNIQUE KEY uk_clientes_email (email),
  KEY idx_clientes_segmento_regiao (segmento, regiao)
) ENGINE=InnoDB;

CREATE TABLE Produtos (
  id_produto     INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  nome           VARCHAR(150) NOT NULL,
  categoria      VARCHAR(60)  NOT NULL,
  subcategoria   VARCHAR(60)  NOT NULL,
  preco_unitario DECIMAL(10,2) NOT NULL DEFAULT 0.00,
  ativo          BOOLEAN NOT NULL DEFAULT TRUE,
  KEY idx_produtos_cat_sub (categoria, subcategoria),
  CONSTRAINT chk_preco_prod CHECK (preco_unitario >= 0)
) ENGINE=InnoDB;

CREATE TABLE Pedidos (
  id_pedido   INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  data_pedido DATE NOT NULL,
  id_Cliente  INT UNSIGNED NOT NULL,
  valor_total DECIMAL(12,2) NOT NULL DEFAULT 0.00,
  status      ENUM('Criado','Faturado','Cancelado') NOT NULL DEFAULT 'Criado',
  KEY idx_pedidos_cliente (id_Cliente),
  KEY idx_pedidos_data (data_pedido),
  CONSTRAINT fk_pedidos_clientes
    FOREIGN KEY (id_Cliente) REFERENCES Clientes(id_Cliente)
    ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT chk_valor_total CHECK (valor_total >= 0)
) ENGINE=InnoDB;

CREATE TABLE Itens_Pedido (
  id_item        INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  id_pedido      INT UNSIGNED NOT NULL,
  id_produto     INT UNSIGNED NOT NULL,
  quantidade     INT UNSIGNED NOT NULL DEFAULT 1,
  preco_unitario DECIMAL(10,2) NOT NULL DEFAULT 0.00,  -- preço congelado no momento da venda (não é FK)
  desconto       DECIMAL(5,2)  NOT NULL DEFAULT 0.00,
  valor_item     DECIMAL(12,2) NOT NULL DEFAULT 0.00,  -- derivado: quantidade * (preco_unitario - desconto)
  KEY idx_itens_pedido_pedido (id_pedido),
  KEY idx_itens_pedido_produto (id_produto),
  CONSTRAINT fk_itens_pedido_pedidos
    FOREIGN KEY (id_pedido) REFERENCES Pedidos(id_pedido)
    ON UPDATE CASCADE ON DELETE CASCADE,
  CONSTRAINT fk_itens_pedido_produtos
    FOREIGN KEY (id_produto) REFERENCES Produtos(id_produto)
    ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT uk_item_unico UNIQUE (id_pedido, id_produto),
  CONSTRAINT chk_qtd_pos CHECK (quantidade >= 1),
  CONSTRAINT chk_prec_pos CHECK (preco_unitario >= 0),
  CONSTRAINT chk_desc_pos CHECK (desconto >= 0),
  CONSTRAINT chk_valor_item CHECK (valor_item >= 0)
) ENGINE=InnoDB;

-- 2) Triggers (Banco de Dados "Ativo") para manter os totais coerentes
DELIMITER $$

CREATE TRIGGER bi_itens_pedido_calc
BEFORE INSERT ON Itens_Pedido
FOR EACH ROW
BEGIN
  SET NEW.valor_item = NEW.quantidade * (NEW.preco_unitario - NEW.desconto);
END $$

CREATE TRIGGER bu_itens_pedido_calc
BEFORE UPDATE ON Itens_Pedido
FOR EACH ROW
BEGIN
  SET NEW.valor_item = NEW.quantidade * (NEW.preco_unitario - NEW.desconto);
END $$

CREATE TRIGGER ai_itens_pedido_sum
AFTER INSERT ON Itens_Pedido
FOR EACH ROW
BEGIN
  UPDATE Pedidos p
    SET p.valor_total = (SELECT COALESCE(SUM(valor_item),0) FROM Itens_Pedido WHERE id_pedido = NEW.id_pedido)
  WHERE p.id_pedido = NEW.id_pedido;
END $$

CREATE TRIGGER au_itens_pedido_sum
AFTER UPDATE ON Itens_Pedido
FOR EACH ROW
BEGIN
  UPDATE Pedidos p
    SET p.valor_total = (SELECT COALESCE(SUM(valor_item),0) FROM Itens_Pedido WHERE id_pedido = NEW.id_pedido)
  WHERE p.id_pedido = NEW.id_pedido;
END $$

CREATE TRIGGER ad_itens_pedido_sum
AFTER DELETE ON Itens_Pedido
FOR EACH ROW
BEGIN
  UPDATE Pedidos p
    SET p.valor_total = (SELECT COALESCE(SUM(valor_item),0) FROM Itens_Pedido WHERE id_pedido = OLD.id_pedido)
  WHERE p.id_pedido = OLD.id_pedido;
END $$

DELIMITER ;

-- 3) Dados de exemplo (opcional)
INSERT INTO Clientes (nome, segmento, regiao, cidade, estado, email) VALUES
('Ana Souza', 'Consumer', 'East', 'São Paulo', 'SP', 'ana.souza@example.com'),
('Bruno Lima', 'Corporate', 'West', 'Rio de Janeiro', 'RJ', 'bruno.lima@example.com');

INSERT INTO Produtos (nome, categoria, subcategoria, preco_unitario, ativo) VALUES
('Cadeira Ergonômica X', 'Furniture', 'Chairs', 899.90, TRUE),
('Mesa Office Pro', 'Furniture', 'Tables', 1299.00, TRUE),
('Telefone IP ZX', 'Technology', 'Phones', 549.50, TRUE);

INSERT INTO Pedidos (data_pedido, id_Cliente, valor_total, status) VALUES
('2025-09-01', 1, 0.00, 'Criado'),
('2025-09-03', 2, 0.00, 'Criado');

INSERT INTO Itens_Pedido (id_pedido, id_produto, quantidade, preco_unitario, desconto, valor_item) VALUES
(1, 1, 1, 899.90, 0.00, 0.00),
(1, 3, 2, 549.50, 20.00, 0.00),
(2, 2, 1, 1299.00, 0.00, 0.00);

-- Recalcular valor_total via triggers já acontece em INSERT/UPDATE/DELETE de Itens_Pedido
-- Consulta de verificação
SELECT p.id_pedido, c.nome AS cliente, p.data_pedido, p.valor_total, p.status
FROM Pedidos p
JOIN Clientes c ON c.id_Cliente = p.id_Cliente
ORDER BY p.id_pedido;
