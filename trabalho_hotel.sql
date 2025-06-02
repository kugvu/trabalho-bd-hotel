-- PASSO 1: Ver os tipos de quartos disponíveis
-- Esta consulta serve apenas para conhecer os diferentes tipos existentes
-- e os seus respetivos IDs, nomes e preços. Isso ajudou-me a escolher o tipo 2 (Duplo)
SELECT * FROM TipoQuarto;



--ver quais quartos estavam livres num hotel e tipo específico para uma data concreta
-- Quero saber quais são os quartos do tipo 2 (Duplo) no hotel com ID = 1
-- que estão livres no dia 2025-06-13. Para isso:
-- 1) Filtrei os quartos do hotel e do tipo desejado
-- 2) Excluí os quartos que já estão ocupados nessa data

SELECT q.numero
FROM quarto q
WHERE q.hotel_id = 1
  AND q.tipo_id = 2
  AND q.quarto_id NOT IN (
    SELECT rh.quarto_id
    FROM reservahospede rh
    WHERE '2025-06-13' BETWEEN rh.data_entrada AND rh.data_saida
  );


-- PASSO 3: Verificar hotéis com restaurantes de categoria (classificação) superior a 3 que sirvam jantar
-- Aqui quis saber que hotéis têm bons restaurantes (categoria > 3)
-- e que oferecem serviço de jantar (tipo_refeicao = 'jantar')
-- Utilizei DISTINCT para evitar repetições do mesmo hotel
SELECT DISTINCT h.nome
FROM hotel h
JOIN RestauranteBar r ON h.hotel_id = r.hotel_id
WHERE r.categoria > 3 AND r.tipo_refeicao = 'jantar';






-- PASSO 4: Ver os hóspedes associados a uma reserva e calcular o valor total
-- Analisei a reserva com ID = 1. Cada hóspede pode ter um regime do alojamento diferente
-- e fiquei interessado em saber o custo de cada um. Assumi que o preço por noite
-- é 100€, apenas para testar o cálculo com DATEDIFF.
SELECT h.nome_completo, h.numerohospede, rh.data_entrada, rh.data_saida, rh.regime,
       DATEDIFF(day, rh.data_entrada, rh.data_saida) * 100 AS preco_total
FROM reservahospede rh
JOIN hospede h ON h.hospede_id = rh.hospede_id
WHERE rh.reserva_id = 1;



-- PASSO 5: Calcular média de hóspedes por reserva e tempo médio de estadia por hotel
-- Esta parte foi mais complexa. O que fiz foi:
-- 1) Criar uma subquery que calcula, por reserva, quantos hóspedes houve
--    e quantos dias ficaram (com base nas datas de entrada e saída)
-- 2) Depois juntei os dados por hotel para calcular as médias
SELECT h.nome, h.cidade, h.pais,
       AVG(sub.qtd_hospedes) AS media_hospedes,
       AVG(sub.dias_estadia) AS media_dias
FROM hotel h
JOIN (
    SELECT q.hotel_id,
           rh.reserva_id,
           COUNT(DISTINCT rh.hospede_id) AS qtd_hospedes,
           AVG(DATEDIFF(day, rh.data_entrada, rh.data_saida)) AS dias_estadia
    FROM reservahospede rh
    JOIN quarto q ON q.quarto_id = rh.quarto_id
    GROUP BY rh.reserva_id, q.hotel_id
) sub ON sub.hotel_id = h.hotel_id
GROUP BY h.nome, h.cidade, h.pais
ORDER BY h.pais, h.cidade;





-- PASSO 6: Verificar se a coluna hotel_id da tabela Reserva estava preenchida
-- Antes de criar uma chave estrangeira ou fazer joins diretos,
-- quis garantir que a coluna hotel_id da tabela Reserva estava atualizada.

SELECT reserva_id, hotel_id
FROM Reserva;



-- PASSO 7: Atualizar a coluna hotel_id com base no quarto reservado
-- Usei o relacionamento entre Reserva, Reservahospede e Quarto para saber
-- a que hotel pertence cada quarto de uma reserva e atualizei esse campo.

UPDATE Reserva
SET hotel_id = q.hotel_id
FROM Reserva r
JOIN reservahospede rh ON r.reserva_id = rh.reserva_id
JOIN quarto q ON q.quarto_id = rh.quarto_id;




-- PASSO 8: Mostrar os dados de cada hóspede e as suas estadias
-- Aqui vi os dados pessoais do hóspede, o hotel onde ficou
-- e calculei o número de acompanhantes (pessoas na mesma reserva)
-- usando uma subquery. Também calculei os dias de estadia com DATEDIFF.

SELECT h.nome_completo, h.numerohospede, h.telefone, h.morada,
       ho.nome AS hotel, ho.cidade, ho.pais,
       DATEDIFF(day, rh.data_entrada, rh.data_saida) AS dias_estadia,
       (
         SELECT COUNT(*)
         FROM reservahospede rh2
         WHERE rh2.reserva_id = rh.reserva_id
       ) AS acompanhantes
FROM hospede h
JOIN reservahospede rh ON rh.hospede_id = h.hospede_id
JOIN reserva r ON r.reserva_id = rh.reserva_id
JOIN hotel ho ON ho.hotel_id = r.hotel_id;

-- PASSO 9: Calcular o  numero total de dormidas por hotel, por mês e por ano
-- Esta análise permitiu perceber a ocupação dos hotéis ao longo do tempo.
-- Agrupei por hotel, mês e ano e somei os dias de estadia de todos os hóspedes.
SELECT h.nome, h.pais,
       MONTH(rh.data_entrada) AS mes,
       YEAR(rh.data_entrada) AS ano,
       SUM(DATEDIFF(day, rh.data_entrada, rh.data_saida)) AS total_dormidas
FROM reservahospede rh
JOIN reserva r ON rh.reserva_id = r.reserva_id
JOIN hotel h ON r.hotel_id = h.hotel_id
GROUP BY h.nome, h.pais, MONTH(rh.data_entrada), YEAR(rh.data_entrada)
ORDER BY h.pais, mes, total_dormidas DESC;