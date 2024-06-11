drop procedure if Exists PROC_DAILY_CASH_RECONCILIATION_REPORT;
DELIMITER $$
CREATE  PROCEDURE `PROC_DAILY_CASH_RECONCILIATION_REPORT`(P_ENTRY_DATE text,P_ACCOUNT text,P_COMPANY_ID Text)
begin

					select 	    'Inflow',
								ABS(B.FORM_AMOUNT),
								B.FORM_F_ID,
								C.Replacment_ID 
					from 		Receipts A
					inner join 	Receipts_Detail B 
					ON 			A.id = B.Receipts_Id 
					inner join 	receipts_detail_junction C
					ON 			B.REPLACMENT_DETAIL_JUNCTION_ID = C.ID
					where 		A.CASH_ACC_ID 			   = P_ACCOUNT
					and 		Convert(A.ENTRY_DATE,Date) = P_ENTRY_DATE
					and 		B.FORM_FLAG 			   = 'E'
					and         B.FORM_AMOUNT > 0
                    and         A.COMANY_ID = P_COMPANY_ID
                    
                    Union All 
                    
                    select  	'Inflow',
								ABS(B.FORM_AMOUNT),
                                B.FORM_F_ID,
                                C.Sale_INVOCIE_ID
					from 		Receipts A 
                    inner join  receipts_detail B 
                    ON          A.id = B.RECEIPTS_ID
                    inner join  Receipts_Detail_Junction C 
                    ON          B.REPLACMENT_DETAIL_JUNCTION_ID = C.ID
                    where       A.CASH_ACC_ID = P_ACCOUNT
                    and         Convert(A.ENTRY_DATE,DATE) = P_ENTRY_DATE
                    and         B.FORM_FLAG = 'I'
                    and         A.COMPANY_ID = P_COMPANY_ID

					UNION ALL 
                    
                    select  	'Inflow',
								ABS(B.FORM_AMOUNT),
                                B.FORM_F_ID,
                                C.STOCK_TRANSFER_ID
					from 		Receipts A 
                    inner join  receipts_detail B 
                    ON          A.id = B.RECEIPTS_ID
                    inner join  Receipts_Detail_Junction C 
                    ON          B.REPLACMENT_DETAIL_JUNCTION_ID = C.ID
                    where       A.CASH_ACC_ID = P_ACCOUNT
                    and         Convert(A.ENTRY_DATE,DATE) = P_ENTRY_DATE
                    and         B.FORM_FLAG = 'T'
                    and         A.COMPANY_ID = P_COMPANY_ID
                    
                    Union All 
                    
                    select  	'Inflow',
								ABS(B.FORM_AMOUNT),
                                B.FORM_F_ID,
                                C.STOCK_TRANSFER_ID
					from 		Payments A 
                    inner join  Payments_detail B 
                    ON          A.id = B.Payments_ID
                    inner join  Payments_Detail_Junction C 
                    ON          B.REPLACMENT_DETAIL_JUNCTION_ID = C.ID
                    where       A.CASH_ACC_ID = P_ACCOUNT
                    and         Convert(A.ENTRY_DATE,DATE) = P_ENTRY_DATE
                    and         B.FORM_FLAG = 'V'
                    and         A.COMPANY_ID = P_COMPANY_ID
                    
                    Union All
                    
                    select  	'Inflow',
								ABS(B.FORM_AMOUNT),
                                B.FORM_F_ID,
                                C.STOCK_TRANSFER_ID
					from 		Payments A 
                    inner join  Payments_detail B 
                    ON          A.id = B.Payments_ID
                    inner join  Payments_Detail_Junction C 
                    ON          B.REPLACMENT_DETAIL_JUNCTION_ID = C.ID
                    where       A.CASH_ACC_ID = P_ACCOUNT
                    and         Convert(A.ENTRY_DATE,DATE) = P_ENTRY_DATE
                    and         B.FORM_FLAG = 'L'
                    and         A.COMPANY_ID = P_COMPANY_ID;
                    
                    

END $$
DELIMITER ;