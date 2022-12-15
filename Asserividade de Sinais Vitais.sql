with primeiroSV as (SELECT
A.NR_ATENDIMENTO ATENDIMENTO
,NVL(obter_nivel_urgencia(A.nr_atendimento),'Sem classificação') classificacao
,OBTER_NOME_USUARIO(A.nm_usuario_triagem) usuario_triagem
,A.ds_sintoma_paciente SINTOMA_PACIENTE
,b.QT_PA_SISTOLICA PA_max_mmHg_SV
,b.qt_pa_diastolica PA_mín_mmHg_SV
,b.qt_freq_cardiaca FC_bpm_SV
,b.qt_freq_resp FR_mrm_SV
,b.QT_GLICEMIA_CAPILAR Glicemia_CAP_SV
,b.QT_SATURACAO_O2 Saturacao_SV
,b.IE_NIVEL_CONSCIENCIA Nivel_Consciencia
,b.QT_TEMP TEMP
,substr(obter_desc_escala_dor(b.CD_ESCALA_DOR),1,255) DS_ESCALA_DOR
,substr(decode(b.cd_escala_dor,'CV','',qt_escala_dor),1,255) DS_GRID_ESCALA_DOR
,substr(b.ds_observacao,1,255) OBSERVACAO_SV
,substr(obter_nome_pf(b.cd_pessoa_fisica),1,40) TECNICO_SV
,row_number() over (partition by A.NR_ATENDIMENTO order by b.dt_sinal_vital) seq
FROM ATENDIMENTO_PACIENTE A,ATENDIMENTO_SINAL_VITAL B
WHERE A.DT_ENTRADA BETWEEN inicio_dia(:DT_INICIAL) and fim_dia(:DT_FINAL)
AND B.NR_ATENDIMENTO(+) = A.nr_atendimento
AND b.ie_situacao = 'A'
AND (a.nr_seq_triagem  = :nr_seq_triagem OR :nr_seq_triagem = 0)
AND (A.NM_USUARIO_triagem = :NOMEUSUARIO OR :NOMEUSUARIO = '0')
AND ((:ie_setor = 'PA' AND obter_setor_atepacu(obter_atepacu_paciente(a.nr_atendimento,'P'), 0) IN (33,84,110,117)) OR
        (:ie_setor = 'PS' AND obter_setor_atepacu(obter_atepacu_paciente(a.nr_atendimento,'P'), 0) IN (34,102,103,104)) OR
        (:ie_setor = 'ALL' AND obter_setor_atepacu(obter_atepacu_paciente(a.nr_atendimento,'P'), 0) IN (33,84,110,117,34,102,103,104)))
ORDER BY DBMS_RANDOM.RANDOM()
)
SELECT ATENDIMENTO, classificacao, usuario_triagem, SINTOMA_PACIENTE,PA_max_mmHg_SV,PA_mín_mmHg_SV,FC_bpm_SV,FR_mrm_SV,Glicemia_CAP_SV,Saturacao_SV,Nivel_Consciencia, TEMP,DS_ESCALA_DOR, DS_GRID_ESCALA_DOR,OBSERVACAO_SV,TECNICO_SV, seq
from primeiroSV 
where seq = 1
and :ie_aud_assert = 1
and rownum <=(CASE WHEN (
 SELECT TRUNC(COUNT(1)) 
 FROM atendimento_paciente x
 WHERE x.dt_entrada BETWEEN inicio_dia(:DT_INICIAL) AND fim_dia(:DT_FINAL)
 AND ((:ie_setor = 'PA' AND obter_setor_atepacu(obter_atepacu_paciente(x.nr_atendimento,'P'), 0) IN (33,84,110,117)) OR
       (:ie_setor = 'PS' AND obter_setor_atepacu(obter_atepacu_paciente(x.nr_atendimento,'P'), 0) IN (34,102,103,104)) OR
       (:ie_setor = 'ALL' AND obter_setor_atepacu(obter_atepacu_paciente(x.nr_atendimento,'P'), 0) IN (33,84,110,117,34,102,103,104)))
  AND (x.nr_seq_triagem  = :nr_seq_triagem OR :nr_seq_triagem = 0)
  AND (x.nm_usuario_triagem = :NOMEUSUARIO OR :NOMEUSUARIO = '0')
  AND EXISTS (SELECT 1
                FROM atendimento_sinal_vital y
               WHERE y.nr_atendimento = x.nr_atendimento
                 AND y.ie_situacao = 'A')
  ) <= 500
  THEN 10
  ELSE 
 (SELECT TRUNC(COUNT(1) * 0.02)  
 FROM atendimento_paciente x
 WHERE x.dt_entrada BETWEEN inicio_dia(:DT_INICIAL) AND fim_dia(:DT_FINAL)
 AND ((:ie_setor = 'PA' AND obter_setor_atepacu(obter_atepacu_paciente(x.nr_atendimento,'P'), 0) IN (33,84,110,117)) OR
       (:ie_setor = 'PS' AND obter_setor_atepacu(obter_atepacu_paciente(x.nr_atendimento,'P'), 0) IN (34,102,103,104)) OR
       (:ie_setor = 'ALL' AND obter_setor_atepacu(obter_atepacu_paciente(x.nr_atendimento,'P'), 0) IN (33,84,110,117,34,102,103,104)))
  AND (x.nr_seq_triagem  = :nr_seq_triagem OR :nr_seq_triagem = 0)
  AND (x.nm_usuario_triagem = :NOMEUSUARIO OR :NOMEUSUARIO = '0')
  AND EXISTS (SELECT 1
                FROM atendimento_sinal_vital y
               WHERE y.nr_atendimento = x.nr_atendimento
                 AND y.ie_situacao = 'A')
  )END)
  
  /*Para a quantidade de registros a serem avaliados, foi adicionado uma cláusula para que quando a quantidade de 
  registros for Menor ou Igual a 500, sejam pegos apenas 10 registros para a conferência.
Caso a quantidade de registros seja maior que 500, será retornado 2% do total de registros.*/


---------------------cabeçalho------------------------------------------

select (SELECT TRUNC(COUNT(1)) 
                     FROM atendimento_paciente x
                     WHERE x.dt_entrada BETWEEN inicio_dia(:DT_INICIAL) AND fim_dia(:DT_FINAL)
                     AND ((:ie_setor = 'PA' AND obter_setor_atepacu(obter_atepacu_paciente(x.nr_atendimento,'P'), 0) IN (33,84,110,117)) OR
                           (:ie_setor = 'PS' AND obter_setor_atepacu(obter_atepacu_paciente(x.nr_atendimento,'P'), 0) IN (34,102,103,104)) OR
                           (:ie_setor = 'ALL' AND obter_setor_atepacu(obter_atepacu_paciente(x.nr_atendimento,'P'), 0) IN (33,84,110,117,34,102,103,104)))
                      AND (x.nr_seq_triagem  = :nr_seq_triagem OR :nr_seq_triagem = 0)
	                  AND (x.nm_usuario_triagem = :NOMEUSUARIO OR :NOMEUSUARIO = '0')
                      AND EXISTS (SELECT 1
                                    FROM atendimento_sinal_vital y
                                   WHERE y.nr_atendimento = x.nr_atendimento
                                     AND y.ie_situacao = 'A')) total_registros, 
                     (SELECT TRUNC(COUNT(1) * 0.10)  
                     FROM atendimento_paciente x
                     WHERE x.dt_entrada BETWEEN inicio_dia(:DT_INICIAL) AND fim_dia(:DT_FINAL)
                     AND ((:ie_setor = 'PA' AND obter_setor_atepacu(obter_atepacu_paciente(x.nr_atendimento,'P'), 0) IN (33,84,110,117)) OR
                           (:ie_setor = 'PS' AND obter_setor_atepacu(obter_atepacu_paciente(x.nr_atendimento,'P'), 0) IN (34,102,103,104)) OR
                           (:ie_setor = 'ALL' AND obter_setor_atepacu(obter_atepacu_paciente(x.nr_atendimento,'P'), 0) IN (33,84,110,117,34,102,103,104)))
                      AND (x.nr_seq_triagem  = :nr_seq_triagem OR :nr_seq_triagem = 0)
	                  AND (x.nm_usuario_triagem = :NOMEUSUARIO OR :NOMEUSUARIO = '0')
                      AND EXISTS (SELECT 1
                                    FROM atendimento_sinal_vital y
                                   WHERE y.nr_atendimento = x.nr_atendimento
                                     AND y.ie_situacao = 'A')
                      ) avaliar from dual