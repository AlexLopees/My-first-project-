USE [BD_Floricultura]

-- INICIO DE CRIA��O DE OBJETOS AVAN�ADOS --

	-- INICIO DE CRIA��O DAS VIEWS --

-- EST� VIEW RETORNA TODAS AS INFORMA��ES DOS CLIENTES

CREATE VIEW uVW_CLIENTE
AS
SELECT 
	C.ID_CLIENTE,
	P.NOME AS 'NOME CLIENTE',
	P.DTNASCIMENTO AS 'DATA DE NASCIMENTO',
	P.CPF,
	P.NUMERO_RG AS 'RG',
	P.FONE,

	CASE
		WHEN C.TIPO_CLIENTE = 'F' THEN 'FISICO'
		WHEN C.TIPO_CLIENTE = 'J' THEN 'JURIDICO'

	ELSE 'N�O CONSTA NO SISTEMA'

END AS 'TIPO CLIENTE'

FROM TB_PESSOA AS P 
	INNER JOIN TB_CLIENTE AS C
		ON P.ID_PESSOA = C.FK_ID_PESSOA

--EXECUTANDO A VIEW--
SELECT * FROM uVW_CLIENTE


--EST� VIEW RETORNA O VALOR TOTAL DE CADA PEDIDO 

ALTER VIEW uVW_PEDIDOS	
AS 
SELECT 
	P.COD_PEDIDO AS 'CODPEDIDO',
	PES.NOME AS 'CLIENTE',
	PRD.COD_PRODUTO AS 'CODPRODUTO',
	PRD.NOME_PRODUTO 'ITEMCOMPRADO',
	C.DESCRICAO,
	PP.ID_PEDIDO_PROD AS 'NUMPEDIDO',
	PRD.VALOR AS 'VALOR UNITARIO',
	PP.QTDE_ITENS_COMPRADOS AS 'QTDECOMPRADO',
	SUM(PP.QTDE_ITENS_COMPRADOS * PRD.VALOR) 'TOTALPEDIDO'

FROM TB_PEDIDO_PRODUTO AS PP
	INNER JOIN TB_PRODUTO AS PRD 
		ON PRD.COD_PRODUTO = PP.FK_COD_PRODUTO

	INNER JOIN TB_CATEGORIA AS C
		ON C.ID_CATEGORIA = PRD.FK_ID_CATEGORIA
	
	INNER JOIN TB_PEDIDO AS P
		ON P.COD_PEDIDO = PP.FK_COD_PEDIDO

	INNER JOIN TB_CLIENTE AS CLI
		ON CLI.ID_CLIENTE = P.FK_ID_CLIENTE

	INNER JOIN TB_PESSOA AS PES
		ON PES.ID_PESSOA = CLI.FK_ID_PESSOA

GROUP BY
	PRD.COD_PRODUTO, PRD.NOME_PRODUTO, PP.ID_PEDIDO_PROD,C.DESCRICAO,
	PRD.VALOR, PP.QTDE_ITENS_COMPRADOS, P.COD_PEDIDO, PES.NOME

--EXECUTANDO A VIEW--
SELECT * FROM uVW_PEDIDOS

/*-----------------------------------------------------------///----------------------------------------------------------------------*/


	--INICIO CRIA��O DAS FUN��ES --

--REAJUSTAR O VALOR COM BASE EM UMA TAXA

CREATE FUNCTION uFN_REAJUSTAR
(
	@VALOR SMALLMONEY,
	@TAXA  SMALLMONEY
)
RETURNS SMALLMONEY
AS
BEGIN
	RETURN @VALOR *(1 + @TAXA/100)
END

--SIMULANDO O REAJUSTE DO VALOR
SELECT 
	P.COD_PRODUTO  AS	[C�DIGO],
	P.NOME_PRODUTO AS	[PRODUTO],
	P.VALOR        AS	[VALOR ATUAL],
	dbo.uFN_REAJUSTAR(VALOR, 40) AS [SIMULADO],
	dbo.uFN_REAJUSTAR(VALOR, 40) -	VALOR
							     AS [DIFERN�A]
FROM TB_PRODUTO P

--EXECUTANDO A FUN��O
UPDATE TB_PRODUTO
SET VALOR = dbo.uFN_REAJUSTAR(VALOR,40)
WHERE COD_PRODUTO IN (16)

SELECT COD_PRODUTO,NOME_PRODUTO,VALOR 
FROM TB_PRODUTO

UPDATE TB_PRODUTO
SET VALOR = 5 WHERE COD_PRODUTO IN(16)


--RETORNA A IDADE 

CREATE FUNCTION uFN_IDADE
(@DTNASCIMENTO DATE)

RETURNS INT 
	AS

BEGIN
	DECLARE @IDADE INT
	SET @IDADE = DATEDIFF(YEAR,@DTNASCIMENTO,CONVERT(DATE,GETDATE()))
	RETURN @IDADE
END

--EXECUTANDO A FUN��O--
SELECT 
	F.MATRICULA AS [CODIGO],
	P.NOME,
	P.DTNASCIMENTO,
	dbo.uFN_IDADE(DTNASCIMENTO)AS [IDADE]
FROM TB_FUNCIONARIO AS F
	INNER JOIN TB_PESSOA AS P
		ON P.ID_PESSOA = F.FK_ID_PESSOA 


-- RETORNA OS MAIORES SALARIOS

CREATE FUNCTION	uFN_SALARIOS_MAIORES
(@SALARIO SMALLMONEY)
RETURNS TABLE
AS
RETURN

	SELECT
		F.MATRICULA,
		P.NOME,
		FUNC.ID_FUNC AS 'CODFUNCAO',
		FUNC.DESCRICAO,
		F.SALARIO
	FROM TB_FUNCIONARIO AS F
		INNER JOIN TB_FUNCAO AS FUNC
			ON FUNC.ID_FUNC = F.FK_FUNCAO 
		INNER JOIN TB_PESSOA AS P
			ON P.ID_PESSOA = F.FK_ID_PESSOA 
	WHERE SALARIO >= @SALARIO

--ESXECUTANDO A FUN��O--
SELECT MATRICULA,NOME,CODFUNCAO,DESCRICAO,SALARIO
FROM uFN_SALARIOS_MAIORES(1600)



--RETORNA A QUANTIDADE DO ESTOQUE 

CREATE FUNCTION uFN_CONSULTA_QTDE_ESTOQUE
(@COD_PRODUTO INT) RETURNS VARCHAR(100)
AS 
BEGIN
	IF @COD_PRODUTO IS NULL RETURN 'PRODUTO (COD) N�O INFORMADO';

	--DECLARA��O DE VARI�VEIS
	DECLARE @QTDE_ATUAL   INT;
	DECLARE @NOME_PRODUTO VARCHAR(50);
	DECLARE @MSGFINAL	  VARCHAR(100);

	--INICIALIZAR VARIAVEIS
	SELECT @QTDE_ATUAL = QTDE_ESTOQUE   FROM TB_PRODUTO WHERE COD_PRODUTO = @COD_PRODUTO;
	SELECT @NOME_PRODUTO = NOME_PRODUTO FROM TB_PRODUTO WHERE COD_PRODUTO = @COD_PRODUTO;

	--RETORNA O SALDO FINAL
	SET @MSGFINAL = CONCAT('O SALDO DO PRODUTO ', @NOME_PRODUTO, ' � ' ,@QTDE_ATUAL, ' UNIDADE.');
	
	RETURN @MSGFINAL;

END;

--EXECUTANDO A FUN��O
SELECT dbo.uFN_CONSULTA_QTDE_ESTOQUE(3) AS [SITUA��O];

SELECT dbo.uFN_CONSULTA_QTDE_ESTOQUE
(COD_PRODUTO) AS [SITUA��O]
FROM TB_PRODUTO 


/*--------------------------------------------------------//----------------------------------------------------------*/

-- INICIO DE CRIA��O DE PROCEDURES --

-- PROCEDIMENTO PARA BUSCAR UM PRODUTO 

CREATE PROCEDURE uSP_BUSCA_PRODUTO
	@NOME_PRODUTO	VARCHAR(50)
AS

SET @NOME_PRODUTO = '%' + @NOME_PRODUTO + '%';

 SELECT
	P.COD_PRODUTO  AS 'CODPRODUTO',
	P.NOME_PRODUTO AS 'PRODUTO',
	C.ID_CATEGORIA AS 'CODCATEGORIA',
	C.DESCRICAO,
	P.VALOR		   AS 'VALOR POR UNIDADE'
FROM TB_CATEGORIA AS C
	INNER JOIN TB_PRODUTO AS P
		ON C.ID_CATEGORIA = P.FK_ID_CATEGORIA
WHERE NOME_PRODUTO LIKE @NOME_PRODUTO

--EXECUTANDO A PROCEDURE--
EXEC uSP_BUSCA_PRODUTO 'ROSA'
EXEC uSP_BUSCA_PRODUTO 'VIOLETA'	
EXEC uSP_BUSCA_PRODUTO '%' 



-- PROCEDIMENTO PARA CADASTRAR UM PRODUTO

CREATE PROCEDURE uSP_PRODUTO_ADD
(
	@NOME_PRODUTO VARCHAR(50),
	@VALOR		  SMALLMONEY,
	@QTDE_ESTOQUE SMALLINT,
	@FK_ID_CATEGORIA INT
)
AS 
BEGIN 
	
	INSERT INTO TB_PRODUTO
	VALUES(@NOME_PRODUTO, @VALOR, @QTDE_ESTOQUE, @FK_ID_CATEGORIA)

END

SELECT COD_PRODUTO,FK_ID_CATEGORIA AS[CODCATEG],NOME_PRODUTO,VALOR FROM TB_PRODUTO

-- EXECUTANDO A PROCEDURE --
EXEC uSP_PRODUTO_ADD 'BONSAI',120,50,2
EXEC uSP_PRODUTO_ADD 'GIRASOL',32,26,5 


--PROCEDIMENTO PARA ALTERAR STATUS DE UM PRODUTO, EM VEZ DE EXCLU�-LO FISICAMENTE.

CREATE PROCEDURE uSP_PRODUTO_DEL
(@CODIGO INT)

AS
BEGIN

	DECLARE @QTDE INT
	SELECT @QTDE = QTDE_ESTOQUE FROM TB_PRODUTO
	WHERE COD_PRODUTO = @CODIGO
	
	IF @QTDE IS NOT NULL
		IF @QTDE = 0
		UPDATE TB_PRODUTO SET QTDE_ESTOQUE = 5
		WHERE COD_PRODUTO = @CODIGO

END

--EXECUTANDO A PROCEDURE

UPDATE TB_PRODUTO SET QTDE_ESTOQUE = 0
WHERE COD_PRODUTO = 15

EXEC uSP_PRODUTO_DEL 15

SELECT * FROM TB_PRODUTO


/*-----------------------------------------------------//----------------------------------------------------*/

--INICIO DE CRIA��O DAS TRIGGERS--

-- ESSA TRIGGER EXIBI O ANTES E O DEPOIS DE CADA ATUALIZA��O NA TABELA PRODUTO

CREATE TRIGGER uTR_UPDATE_PRODUTO
ON TB_PRODUTO
FOR UPDATE 
AS
	BEGIN
		--ANTES DA ATUALIZA��O
			SELECT P.*FROM DELETED P
			INNER JOIN TB_PRODUTO PRD
				ON P.COD_PRODUTO = PRD.COD_PRODUTO
		
		--DEPOIS DA ATUALIZA��O
			SELECT I.* FROM INSERTED I
			INNER JOIN TB_PRODUTO PRD
				ON I.COD_PRODUTO = PRD.COD_PRODUTO
	END

--DISPARANDO A TRIGGER
UPDATE TB_PRODUTO SET QTDE_ESTOQUE = 12
WHERE COD_PRODUTO = 15


/* 
	ESSA TRIGGER FAZ O CONTROLE DO ESTOQUE, N�O DEIXANDO QUE ELE FIQUE NEGATIVO 
	CASO O ESTOQUE N�O SEJA SUFICIENTE PARA ATENDER O PEDIDO 
*/

CREATE OR ALTER TRIGGER uTR_CONTROLE_ESTOQUE
ON TB_PEDIDO_PRODUTO
INSTEAD OF INSERT, UPDATE
AS
  DECLARE @QTDE_FUTURA INT
  SELECT  @QTDE_FUTURA = P.QTDE_ESTOQUE - I.QTDE_ITENS_COMPRADOS
 
	FROM TB_PRODUTO P
		INNER JOIN INSERTED I
	ON P.COD_PRODUTO = I.FK_COD_PRODUTO

  IF @QTDE_FUTURA < 0
    RAISERROR('ESTOQUE INSUFICIENTE! N�O FOI POSS�VEL REALIZAR SEU PEDIDO.',16,1)

  ELSE
	BEGIN
		 INSERT INTO TB_PEDIDO_PRODUTO
		 SELECT FK_COD_PEDIDO, FK_COD_PRODUTO, QTDE_ITENS_COMPRADOS
		 FROM INSERTED 

		 UPDATE PROD
		 SET
		 QTDE_ESTOQUE = QTDE_ESTOQUE - PP.QTDE_ITENS_COMPRADOS
		 FROM TB_PRODUTO AS PROD
			INNER JOIN INSERTED PP
		 ON PROD.COD_PRODUTO = PP.FK_COD_PRODUTO
	END

--DISPARANDO A TRIGGER 1� EXEMPLO VAI GERAR UM ERRO POIS, A QTDE DO ESTOQUE � INSUFICIENTE

INSERT INTO TB_PEDIDO_PRODUTO(FK_COD_PEDIDO, FK_COD_PRODUTO, QTDE_ITENS_COMPRADOS)
VALUES
	(10000,22,25)

--DISPARANDO A TRIGGER 2� EXEMPLO VAI EFETUAR O PEDIDO E ATUALIZAR MINHAS TABELAS

INSERT INTO TB_PEDIDO_PRODUTO(FK_COD_PEDIDO, FK_COD_PRODUTO, QTDE_ITENS_COMPRADOS)
VALUES
	(10007,1,50)



SELECT * FROM TB_PEDIDO_PRODUTO
SELECT * FROM TB_PRODUTO