drop procedure if Exists PROC_DAILY_CASH_RECONCILIATION_REPORT;
DELIMITER $$
CREATE  PROCEDURE `PROC_DAILY_CASH_RECONCILIATION_REPORT`(P_ENTRY_DATE text,P_ACCOUNT text,P_COMPANY_ID Text)
begin

					
                    select A.id,A.CashFlow,SUM(A.Amount) as Amount,A.FormReference,A.FormId,A.ConflictionFlag,A.FORM_FLAG
                    from (
			select 	    
				B.id,
				'Inflow' as CashFlow,
				ABS(B.FORM_AMOUNT) as Amount,
				B.FORM_F_ID as FormReference,
				C.REPLACEMENT_ID as FormId,
                                'Receipts' as ConflictionFlag,
				'Replacement' as FORM_FLAG
			from 		Receipts A
			inner join 	Receipts_Detail B 
			ON 		A.id = B.Receipts_Id 
			inner join 	receipts_detail_junction C
			ON 		B.RECEIPTS_DETAIL_JUNCTION_ID = C.ID
			where 		A.CASH_ACC_ID 			   = P_ACCOUNT
			and 		Convert(A.ENTRY_DATE,Date) = Convert(P_ENTRY_DATE,Date)
			and 		B.FORM_FLAG 			   = 'E'
			and             B.FORM_AMOUNT > 0
                        and         A.COMPANY_ID = P_COMPANY_ID
                    
                    Union All 
                    
                    select  	
				B.id,
				'Inflow' as CashFlow,
				ABS(B.FORM_AMOUNT) as Amount,
                                B.FORM_F_ID as FormReference,
                                C.Sale_INVOICE_ID as FormId,
                                'Receipts' as ConflictionFlag,
				'SaleInvoice' as Form_Flag
		    from 	Receipts A 
                    inner join  receipts_detail B 
                    ON          A.id = B.RECEIPTS_ID
                    inner join  Receipts_Detail_Junction C 
                    ON          B.RECEIPTS_DETAIL_JUNCTION_ID = C.ID
                    where       A.CASH_ACC_ID = P_ACCOUNT
                    and         Convert(A.ENTRY_DATE,DATE) = Convert(P_ENTRY_DATE,Date)
                    and         B.FORM_FLAG = 'I'
                    and         A.COMPANY_ID = P_COMPANY_ID

					UNION ALL 
                    
                    select  	
				B.id,
				'Inflow' as CashFlow,
				ABS(B.FORM_AMOUNT) as Amount,
                                B.FORM_F_ID as FormReference,
                                C.STOCK_TRANSFER_ID  as FormId,
                                'Receipts' as ConflictionFlag,
				'StockTransfer' as Form_Flag
		   from 	Receipts A 
                    inner join  receipts_detail B 
                    ON          A.id = B.RECEIPTS_ID
                    inner join  Receipts_Detail_Junction C 
                    ON          B.RECEIPTS_DETAIL_JUNCTION_ID = C.ID
                    where       A.CASH_ACC_ID = P_ACCOUNT
                    and         Convert(A.ENTRY_DATE,DATE) = Convert(P_ENTRY_DATE,Date)
                    and         B.FORM_FLAG = 'T'
                    and         A.COMPANY_ID = P_COMPANY_ID
                    
                    Union All 
                    
                    select  	
				B.id,
				'Inflow' as CashFlow,
				ABS(B.FORM_AMOUNT) as Amount,
                                B.FORM_F_ID as FormReference,
                                C.VCM_ID as FormId,
                                'Payments' as ConflictionFlag,
				'VendorCreditMemo' as Form_Flag
		    from 	Payments A 
                    inner join  Payments_detail B 
                    ON          A.id = B.Payments_ID
                    inner join  Payments_Detail_Junction C 
                    ON          B.Payments_DETAIL_JUNCTION_ID = C.ID
                    where       A.CASH_ACC_ID = P_ACCOUNT
                    and         Convert(A.ENTRY_DATE,DATE) = Convert(P_ENTRY_DATE,Date)
                    and         B.FORM_FLAG = 'V'
                    and         A.COMPANY_ID = P_COMPANY_ID
                    
                    Union All
                    
                    select  	
				B.id,
				'Inflow' as CashFlow,
				ABS(B.FORM_AMOUNT) as Amount,
                                B.FORM_F_ID as FormReference,
                                C.PARTIAL_CREDIT_ID as FormId,
                                'Payments' as ConflictionFlag,
				'PartialCreditVoucher' as Form_Flag
		    from 	Payments A 
                    inner join  Payments_detail B 
                    ON          A.id = B.Payments_ID
                    inner join  Payments_Detail_Junction C 
                    ON          B.Payments_DETAIL_JUNCTION_ID = C.ID
                    where       A.CASH_ACC_ID = P_ACCOUNT
                    and         Convert(A.ENTRY_DATE,DATE) = Convert(P_ENTRY_DATE,Date)
                    and         B.FORM_FLAG = 'L'
                    and         A.COMPANY_ID = P_COMPANY_ID 
                    )A group by A.id,A.CashFlow,A.FormReference,A.FormId,A.ConflictionFlag,A.FORM_FLAG
		    with rollup having A.id is null OR A.FORM_FLAG is not null
                    
		    Union ALL 
					
		select A.id,A.CashFlow,SUM(A.Amount) as Amount,A.FormReference,A.FormId,A.ConflictionFlag,A.FORM_FLAG
                    from (
                          select 	    
				    B.id,
				   'Outflow' as CashFlow,
				    ABS(B.FORM_AMOUNT) as Amount,
				    B.FORM_F_ID as FormReference,
				    C.RECEIVING_ID as FormId,
                                    'Payments' as ConflictionFlag,
				    'ReceiveOrder' as Form_Flag
			  from 		Payments A
			  inner join 	Payments_Detail B 
			  ON 		A.id = B.Payments_Id 
			  inner join 	Payments_detail_junction C
			  ON 		B.Payments_DETAIL_JUNCTION_ID = C.ID
			  where 	A.CASH_ACC_ID 			   = P_ACCOUNT
			  and 		Convert(A.ENTRY_DATE,Date) = Convert(P_ENTRY_DATE,Date)
			  and 		B.FORM_FLAG 			   = 'R'
                    	  and           A.COMPANY_ID = P_COMPANY_ID
                    
                      Union All 
                    
                        select 	    
					B.id,
					'Outflow' as CashFlow,
					ABS(B.FORM_AMOUNT) as Amount,
					B.FORM_F_ID as FormReference,
					C.Sale_Return_ID as FormId,
                                       'Receipts' as ConflictionFlag,
					'SaleReturn' as Form_Flag
			from 		Receipts A
			inner join 	Receipts_Detail B 
			ON 			A.id = B.Receipts_Id 
			inner join 	Receipts_detail_junction C
			ON 		B.Receipts_DETAIL_JUNCTION_ID = C.ID
			where 		A.CASH_ACC_ID 			   = P_ACCOUNT
			and 		Convert(A.ENTRY_DATE,Date) = Convert(P_ENTRY_DATE,Date)
			and 		B.FORM_FLAG 			   = 'S'
                        and             A.COMPANY_ID = P_COMPANY_ID
                    
                    Union All 
                    
                      select 	    
					B.id,
					'Outflow' as CashFlow,
					ABS(B.FORM_AMOUNT) as Amount,
					B.FORM_F_ID as FormReference,
					C.Stock_In_ID as FormId,
                                       'Payments' as ConflictionFlag,
					'StockIn' as Form_Flag
			from 		Payments A
			inner join 	Payments_Detail B 
			ON 		A.id = B.Payments_Id 
			inner join 	Payments_detail_junction C
			ON 		B.Payments_DETAIL_JUNCTION_ID = C.ID
			where 		A.CASH_ACC_ID 			   = P_ACCOUNT
			and 		Convert(A.ENTRY_DATE,Date) = Convert(P_ENTRY_DATE,Date)
			and 		B.FORM_FLAG 			   = 'N'
                        and             A.COMPANY_ID = P_COMPANY_ID
					
			Union All 
					
			select 	    
					B.id,
					'Outflow' as CashFlow,
					ABS(B.FORM_AMOUNT) as Amount,
					B.FORM_F_ID as FormReference,
					C.REPLACEMENT_ID as FormId,
                                       'Receipts' as ConflictionFlag,
					'Replacement' as Form_Flag
			from 		Receipts A
			inner join 	Receipts_Detail B 
			ON 		A.id = B.Receipts_Id 
			inner join 	receipts_detail_junction C
			ON 		B.RECEIPTS_DETAIL_JUNCTION_ID = C.ID
			where 		A.CASH_ACC_ID 			   = P_ACCOUNT
			and 		Convert(A.ENTRY_DATE,Date) = Convert(P_ENTRY_DATE,Date)
			and 		B.FORM_FLAG 			   = 'E'
			and             B.FORM_AMOUNT < 0
                    	and             A.COMPANY_ID = P_COMPANY_ID
					
			Union All 
					
			select 	    
					B.id,
					'Outflow' as CashFlow,
					ABS(B.FORM_AMOUNT) as Amount,
					B.FORM_F_ID as FormReference,
					C.PARTIAL_CREDIT_ID as FormId,
                                        'Receipts' as ConflictionFlag,
					'PartialCreditVoucher' as Form_Flag
			from 		Receipts A
			inner join 	Receipts_Detail B 
			ON 		A.id = B.Receipts_Id 
			inner join 	Receipts_detail_junction C
			ON 		B.Receipts_DETAIL_JUNCTION_ID = C.ID
			where 		A.CASH_ACC_ID 			   = P_ACCOUNT
			and 		Convert(A.ENTRY_DATE,Date) = Convert(P_ENTRY_DATE,Date)
			and 		B.FORM_FLAG 			   = 'L'
                        and         A.COMPANY_ID = P_COMPANY_ID
			)A group by A.id,A.CashFlow,A.FormReference,A.FormId,A.ConflictionFlag,A.FORM_FLAG
			   with rollup having A.id is null OR A.FORM_FLAG is not null;

END $$
DELIMITER ;
