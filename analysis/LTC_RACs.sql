/****** Script for SelectTopNRows command from SSMS  ******/
SELECT distinct RAC_CODE, count(MEDICAID_RECIPIENT_ID) as id_cnt
  FROM [PHClaims].[dbo].[mcaid_elig_rac]
  where RAC_CODE in ('1243', '1242', '1241', '1240', '1239', '1238', '1237', '1236', '1235', '1234', '1233', '1232', '1231', '1230', '1229', '1228', '1227', '1226', '1225', '1224', '1223', '1222', '1221', '1220', '1219', '1218', '1169', '1168', '1167', '1166', '1165', '1164', '1163', '1162', '1157', '1156', '1155', '1154', '1153', '1152', '1175', '1151', '1150', '1174', '1149', '1148', '1147', '1146', '1189', '1092', '1188', '1091', '1090', '1089', '1088', '1187', '1087', '1086', '1186', '1085', '1084', '1083', '1074', '1073', '1072', '1071', '1070', '1069', '1068', '1067', '1066', '1065', '1180', '1062', '1061', '1179', '1060', '1059', '1055', '1054', '1053', '1052')
  group by RAC_CODE