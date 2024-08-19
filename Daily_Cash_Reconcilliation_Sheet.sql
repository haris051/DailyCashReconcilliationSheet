Alter Table Company
Add Account_Id int;

update Company A 
inner join accounts_id B 
on A.id = B.Company_Id 
SET A.Account_Id = B.id 
where B.ACC_ID = 1020;

Alter Table Company 
Modify Account_ID int null;

drop view if exists vw_Company; 
CREATE VIEW `vw_company` AS
    SELECT 
        `a`.`ID` AS `ID`,
        `a`.`COMPANY_ID` AS `COMPANY_ID`,
        `a`.`COMPANY_NAME` AS `COMPANY_NAME`,
        `a`.`CURRENCY_NAME` AS `CURRENCY_NAME`,
        `a`.`CURRENCY_SIGN` AS `CURRENCY_SIGN`,
        `a`.`IS_DESC_SALES` AS `IS_DESC_SALES`,
        `a`.`MAILING_ADDRESS` AS `MAILING_ADDRESS`,
        `a`.`CITY` AS `CITY`,
        `a`.`STATE` AS `STATE`,
        `a`.`ZIP` AS `ZIP`,
        `a`.`COUNTRY` AS `COUNTRY`,
        `a`.`TELEPHONE` AS `TELEPHONE`,
        `a`.`EMAIL` AS `EMAIL`,
        `a`.`CURRENCY_CLASS` AS `CURRENCY_CLASS`,
        `a`.`SALES_TAX_VALUE` AS `SALES_TAX_VALUE`,
        `a`.`SALES_TAX_LABEL` AS `SALES_TAX_LABEL`,
        `a`.`SALES_TAX_NO` AS `SALES_TAX_NO`,
        `a`.`SALE_PRICE_FLAG` AS `SALE_PRICE_FLAG`,
        `a`.`MERGE_CURRENT_STOCK` AS `MERGE_CURRENT_STOCK`,
        `a`.`CLIENT_ID` AS `CLIENT_ID`,
        `a`.`COMPANY_WEBSITE` AS `COMPANY_WEBSITE`,
        `a`.`DEFAULT_INVENTORY_TYPE_ID` AS `DEFAULT_INVENTORY_TYPE_ID`,
        `a`.`DEFAULT_ITEM_TYPE_ID` AS `DEFAULT_ITEM_TYPE_ID`,
        `a`.`DEFAULT_PAYMENT_TYPE` AS `DEFAULT_PAYMENT_TYPE`,
        `a`.`DEFAULT_SHIPPING_TYPE` AS `DEFAULT_SHIPPING_TYPE`,
        `a`.`DEFAULT_FORM_ID` AS `DEFAULT_FORM_ID`,
        `a`.`DEFAULT_PAYMENT_REFERENCE` AS `DEFAULT_PAYMENT_REFERENCE`,
        `a`.`ITEM_IDENTITY` AS `ITEM_IDENTITY`,
        `a`.`Account_Id` as `Account_Id`
    FROM
        `company` `a`
    ORDER BY `a`.`COMPANY_NAME`;

drop view if exists vw_company_account_id;
CREATE VIEW `vw_company_account_id` AS
    SELECT 
        `b`.`id`,
        `b`.`ACC_ID`,
        `b`.`Description`,
        `a`.`id` as `Company_Id`
    FROM
        `company` `a`
	inner join 
		 `accounts_id` `b`
	on 
		 `a`.`Account_Id` = `b`.`id`;


create table Daily_Cash_Reconciliation_Sheet(
						id int not null primary key AUTO_INCREMENT,
						Entry_Date Date,
						ACC_ID int,
						Company_ID int,
						Inflow Decimal(22,2),
						Outflow Decimal(22,2),
						Beginning_Balance Decimal(22,2),
						Ending_Balance Decimal(22,2)
					    );




drop procedure if Exists PROC_DAILY_CASH_RECONCILIATION_REPORT;
DELIMITER $$
CREATE  PROCEDURE `PROC_DAILY_CASH_RECONCILIATION_REPORT`(P_ENTRY_DATE text,P_ACCOUNT_ID text,P_COMPANY_ID Text,P_START int,P_LENGTH int,P_Flow_Flag Text)
begin

			Declare Last_Entry_Date Text DEFAULT '';
			Declare Previous_Entry_Date Text DEFAULT '';
			Declare User_Entry_Date Text Default '';
			Declare Is_ENTRY_Date_Exists Text Default '';
            Declare Beginning_Balance DECIMAL(22,2) Default 0;
            Declare Closing_Report Text Default '';
            
			
			if (P_Flow_Flag = "InFlow")
			then 
					select MAX(ENTRY_DATE) into Last_Entry_Date from Daily_Cash_Reconciliation_Sheet where ACC_ID = P_ACCOUNT_ID and Company_ID = P_COMPANY_ID;
					select Entry_Date into Is_ENTRY_Date_Exists from Daily_Cash_Reconciliation_Sheet where Entry_Date = Convert(P_ENTRY_DATE,Date) and ACC_ID = P_ACCOUNT_ID and Company_ID = P_COMPANY_ID;
					
					
					if Last_Entry_Date is null OR Last_Entry_Date = '' and Is_ENTRY_Date_Exists = '' OR IS_ENTRY_DATE_EXISTS is null
							then 
								SET User_Entry_Date = Convert(P_ENTRY_DATE,Date);
								SET Previous_Entry_Date = Convert(P_ENTRY_DATE,Date);
								SET Closing_Report = 'Allowed';
                                
								select IFNULL(BEGINNING_BALANCE,0) into Beginning_Balance from Daily_Cash_Reconciliation_Sheet where Convert(Entry_Date,Date) = Convert(Previous_Entry_date,Date) and ACC_ID = P_ACCOUNT_ID and Company_ID = P_COMPANY_ID;

								ELSEIF Convert(P_ENTRY_DATE,Date) > Convert(Last_Entry_Date,Date) and Is_ENTRY_Date_Exists = ''
								then 
									
									SET User_Entry_Date = Convert(P_ENTRY_DATE,Date);
									SET Previous_Entry_Date = Convert(Last_Entry_Date,Date);
									Set Closing_Report = 'Allowed';
									select IFNULL(ENDING_BALANCE,0) into Beginning_Balance from	Daily_Cash_Reconciliation_Sheet	where Convert(Entry_Date,Date) = Convert(Previous_Entry_date,Date) and ACC_ID = P_ACCOUNT_ID and Company_ID = P_COMPANY_ID;

								ELSEif Convert(P_ENTRY_DATE,Date) <= Convert(Last_Entry_Date,Date) and Is_ENTRY_Date_Exists <> ''
								then 
									
									select MAX(ENTRY_DATE) into Previous_Entry_Date from Daily_Cash_Reconciliation_Sheet where Convert(ENTRY_DATE,Date) < Convert(P_ENTRY_DATE,Date) and ACC_ID = P_ACCOUNT_ID and Company_ID = P_COMPANY_ID;
									Set Closing_Report = 'Not_Allowed';
                                    /*IF Entry Date is First Entry Date*/
									if Previous_Entry_Date is null or Previous_Entry_Date = ''
										then 
                                        
											SET User_Entry_Date = Convert(P_ENTRY_DATE,Date);
											SET Previous_Entry_Date = Convert(P_ENTRY_DATE,Date);
									
                                            select IFNULL(BEGINNING_BALANCE,0) into Beginning_Balance from	Daily_Cash_Reconciliation_Sheet	where Convert(Entry_Date,Date) = Convert(Previous_Entry_date,Date) and ACC_ID = P_ACCOUNT_ID and Company_ID = P_COMPANY_ID;

									else 
											SET User_Entry_Date = Convert(P_ENTRY_DATE,Date);
											select IFNULL(ENDING_BALANCE,0) into Beginning_Balance from	Daily_Cash_Reconciliation_Sheet	where Convert(Entry_Date,Date) = Convert(Previous_Entry_date,Date) and Convert(User_Entry_Date,Date)<>Convert(Previous_Entry_Date,Date) and ACC_ID = P_ACCOUNT_ID and Company_ID = P_COMPANY_ID;

                                            
									End if;
						
							ELSE
									Set Closing_Report = 'Not_Allowed';
									SET User_Entry_Date = '';
									SET Previous_Entry_Date = '';
							    /*No Records Found*/
							
					END IF;
							
						

								select *,Count(*) Over() as Total_ROWS,SUM(A.Amount) Over() as Total_InFlow,IFNULL(Beginning_Balance,0) as Beginning_Balance,Closing_Report as Closing_Report
                                from(
										
										            
										select 	    
													B.id,
													'Inflow' 					 as Cash_Flow,
													 Round(ABS(B.FORM_AMOUNT),2) as Amount,
													 B.FORM_F_ID 				 as Form_Reference,
													 C.REPLACEMENT_ID 			 as Form_Id,
													 'Receipts' 				 as Confliction_Flag,
													 'Replacement' 				 as Form_Flag
										from 		  
													  Receipts A
										inner join	  Receipts_Detail B 
										ON 			  A.id = B.Receipts_Id 
										inner join 	  receipts_detail_junction C
										ON 			  B.RECEIPTS_DETAIL_JUNCTION_ID = C.ID
										where 		  A.CASH_ACC_ID 			    = P_ACCOUNT_ID
										And 
													  case	
															when Convert(A.R_ENTRY_DATE,Date)>Convert(Previous_Entry_Date,Date) then Convert(A.R_ENTRY_DATE,Date)>Convert(Previous_Entry_Date,Date)
															when Convert(Previous_Entry_Date,Date) = Convert(User_Entry_Date,Date) then Convert(A.R_ENTRY_DATE,Date) = Convert(User_Entry_Date,Date)
													  END
										and           
													  case 
															when Convert(A.R_ENTRY_DATE,Date) <= Convert(User_Entry_Date,Date) then Convert(A.R_ENTRY_DATE,Date) <= Convert(User_Entry_Date,Date)
															when Convert(Previous_Entry_Date,Date) = Convert(User_Entry_Date,Date) then Convert(A.R_ENTRY_DATE,Date) = Convert(User_Entry_Date,Date)
													  END
										and   	      B.FORM_FLAG 			        = 'E'
										and           B.FORM_AMOUNT > 0
										and           A.COMPANY_ID = P_COMPANY_ID
										
										Union All 
										
										select  	
													   B.id,
													  'Inflow' 						as Cash_Flow,
													   Round(ABS(B.FORM_AMOUNT),2) 	as Amount,
													   B.FORM_F_ID 					as Form_Reference,
													   C.Sale_INVOICE_ID 			as Form_Id,
													   'Receipts' 					as Confliction_Flag,
													   'SaleInvoice' 				as Form_Flag
										from 	
														Receipts A 
										inner join  	receipts_detail B 
										ON    	        A.id = B.RECEIPTS_ID
										inner join  	Receipts_Detail_Junction C 
										ON    	        B.RECEIPTS_DETAIL_JUNCTION_ID = C.ID
										where   		A.CASH_ACC_ID = P_ACCOUNT_ID
										And 
													  case	
															when Convert(A.R_ENTRY_DATE,Date)>Convert(Previous_Entry_Date,Date) then Convert(A.R_ENTRY_DATE,Date)>Convert(Previous_Entry_Date,Date)
															when Convert(Previous_Entry_Date,Date) = Convert(User_Entry_Date,Date) then Convert(A.R_ENTRY_DATE,Date) = Convert(User_Entry_Date,Date)
													  END
										and           
													  case 
															when Convert(A.R_ENTRY_DATE,Date) <= Convert(User_Entry_Date,Date) then Convert(A.R_ENTRY_DATE,Date) <= Convert(User_Entry_Date,Date)
															when Convert(Previous_Entry_Date,Date) = Convert(User_Entry_Date,Date) then Convert(A.R_ENTRY_DATE,Date) = Convert(User_Entry_Date,Date)
													  END		   
										and		        	B.FORM_FLAG = 'I'
										and    	        	A.COMPANY_ID = P_COMPANY_ID
										
										Union All 
										
										select  	
														B.id,
														'Inflow' 			 			 as Cash_Flow,
														Round(ABS(B.FORM_AMOUNT),2) 	 as Amount,
														B.FORM_F_ID 		 			 as Form_Reference,
														C.STOCK_TRANSFER_ID  			 as Form_Id,
														'Receipts'			 			 as Confliction_Flag,
														'StockTransfer' 				 as Form_Flag
										from 	
														Receipts A 
										inner join 	    receipts_detail B 
										ON     		   	A.id = B.RECEIPTS_ID
										inner join  	Receipts_Detail_Junction C 
										ON     		    B.RECEIPTS_DETAIL_JUNCTION_ID = C.ID
										where     		A.CASH_ACC_ID = P_ACCOUNT_ID
										And 
													  case	
															when Convert(A.R_ENTRY_DATE,Date)>Convert(Previous_Entry_Date,Date) then Convert(A.R_ENTRY_DATE,Date)>Convert(Previous_Entry_Date,Date)
															when Convert(Previous_Entry_Date,Date) = Convert(User_Entry_Date,Date) then Convert(A.R_ENTRY_DATE,Date) = Convert(User_Entry_Date,Date)
													  END
										and           
													  case 
															when Convert(A.R_ENTRY_DATE,Date) <= Convert(User_Entry_Date,Date) then Convert(A.R_ENTRY_DATE,Date) <= Convert(User_Entry_Date,Date)
															when Convert(Previous_Entry_Date,Date) = Convert(User_Entry_Date,Date) then Convert(A.R_ENTRY_DATE,Date) = Convert(User_Entry_Date,Date)
													  END
										and     	    	B.FORM_FLAG = 'T'
										and    		    	A.COMPANY_ID = P_COMPANY_ID
										
										Union All 
										
										select  	
												    B.id,
												    'Inflow' 	    			 as Cash_Flow,
												    Round(ABS(B.FORM_AMOUNT),2)  as Amount,
												    B.FORM_F_ID 				 as Form_Reference,
												    C.VCM_ID 	    			 as Form_Id,
												    'Payments' 	    			 as Confliction_Flag,
												    'VendorCreditMemo'  		 as Form_Flag
										from 	
												    Payments A 
										inner join 	    Payments_detail B 
										ON    		    A.id = B.Payments_ID
										inner join 	    Payments_Detail_Junction C 
										ON         	    B.Payments_DETAIL_JUNCTION_ID = C.ID
										where    	    A.CASH_ACC_ID = P_ACCOUNT_ID
										And 
													  case	
															when Convert(A.PAY_ENTRY_DATE,Date)>Convert(Previous_Entry_Date,Date) then Convert(A.PAY_ENTRY_DATE,Date)>Convert(Previous_Entry_Date,Date)
															when Convert(Previous_Entry_Date,Date) = Convert(User_Entry_Date,Date) then Convert(A.PAY_ENTRY_DATE,Date) = Convert(User_Entry_Date,Date)
													  END
										and           
													  case 
															when Convert(A.PAY_ENTRY_DATE,Date) <= Convert(User_Entry_Date,Date) then Convert(A.PAY_ENTRY_DATE,Date) <= Convert(User_Entry_Date,Date)
															when Convert(Previous_Entry_Date,Date) = Convert(User_Entry_Date,Date) then Convert(A.PAY_ENTRY_DATE,Date) = Convert(User_Entry_Date,Date)
													  END
										and      	    	B.FORM_FLAG = 'V'
										and      	    	A.COMPANY_ID = P_COMPANY_ID
						
										Union All 
										
										select  	
												B.id,
												'Inflow' 							as Cash_Flow,
												Round(ABS(B.FORM_AMOUNT),2) 		as Amount,
												B.FORM_F_ID 						as Form_Reference,
												C.PARTIAL_CREDIT_ID     			as Form_Id,
												'Payments' 							as Confliction_Flag,
												'PartialCreditVoucher'  			as Form_Flag
										from 	
													Payments A 
										inner join  Payments_detail B 
										ON          A.id = B.Payments_ID
										inner join 	Payments_Detail_Junction C 
										ON         	B.Payments_DETAIL_JUNCTION_ID = C.ID
										where   	A.CASH_ACC_ID = P_ACCOUNT_ID
										And 
													  case	
															when Convert(A.PAY_ENTRY_DATE,Date)>Convert(Previous_Entry_Date,Date) then Convert(A.PAY_ENTRY_DATE,Date)>Convert(Previous_Entry_Date,Date)
															when Convert(Previous_Entry_Date,Date) = Convert(User_Entry_Date,Date) then Convert(A.PAY_ENTRY_DATE,Date) = Convert(User_Entry_Date,Date)
													  END
										and           
													  case 
															when Convert(A.PAY_ENTRY_DATE,Date) <= Convert(User_Entry_Date,Date) then Convert(A.PAY_ENTRY_DATE,Date) <= Convert(User_Entry_Date,Date)
															when Convert(Previous_Entry_Date,Date) = Convert(User_Entry_Date,Date) then Convert(A.PAY_ENTRY_DATE,Date) = Convert(User_Entry_Date,Date)
													  END
										and       	    	B.FORM_FLAG = 'L'
										and      	    	A.COMPANY_ID = P_COMPANY_ID
								)A Limit P_START,P_LENGTH;
								
			
			end if;
			
			if (P_Flow_Flag = "OutFlow")
			then 
					select MAX(ENTRY_DATE) into Last_Entry_Date from Daily_Cash_Reconciliation_Sheet where ACC_ID = P_ACCOUNT_ID and Company_ID = P_COMPANY_ID;
					select Entry_Date into Is_ENTRY_Date_Exists from Daily_Cash_Reconciliation_Sheet where Convert(Entry_Date,Date) = Convert(P_ENTRY_DATE,Date) and ACC_ID = P_ACCOUNT_ID and Company_ID = P_COMPANY_ID;

					
					
					if Last_Entry_Date is null OR Last_Entry_Date = '' and Is_ENTRY_Date_Exists = ''
							then 
							
								SET User_Entry_Date = Convert(P_ENTRY_DATE,Date);
								SET Previous_Entry_Date = Convert(P_ENTRY_DATE,Date);
							    SET Closing_Report = 'Allowed';
								select  IFNULL(BEGINNING_BALANCE,0) into Beginning_Balance from Daily_Cash_Reconciliation_Sheet where Convert(Entry_Date,Date) = Convert(Previous_Entry_date,Date) and ACC_ID = P_ACCOUNT_ID and Company_ID = P_COMPANY_ID;

                                
								ELSEIF Convert(P_ENTRY_DATE,Date) > Convert(Last_Entry_Date,Date) and Is_ENTRY_Date_Exists = ''
								then 
									
									SET User_Entry_Date = Convert(P_ENTRY_DATE,Date);
									SET Previous_Entry_Date = Convert(Last_Entry_Date,Date);
									SET Closing_Report = 'Allowed';
									select IFNULL(ENDING_BALANCE,0) into Beginning_Balance from	Daily_Cash_Reconciliation_Sheet	where Convert(Entry_Date,Date) = Convert(Previous_Entry_date,Date) and ACC_ID = P_ACCOUNT_ID and Company_ID = P_COMPANY_ID;

								ELSEif Convert(P_ENTRY_DATE,Date) <= Convert(Last_Entry_Date,Date) and Is_ENTRY_Date_Exists <> ''
								then 
									
									Set Closing_Report = 'Not_Allowed';
									select MAX(ENTRY_DATE) into Previous_Entry_Date from Daily_Cash_Reconciliation_Sheet where ENTRY_DATE < Convert(P_ENTRY_DATE,Date) and ACC_ID = P_ACCOUNT_ID and Company_ID = P_COMPANY_ID;
									/*IF Entry Date is First Entry Date*/
                                    if Previous_Entry_Date is null or Previous_Entry_Date = ''
										then 
                                        
											SET User_Entry_Date = Convert(P_ENTRY_DATE,Date);
									        SET Previous_Entry_Date = Convert(P_ENTRY_DATE,Date);
											select  IFNULL(BEGINNING_BALANCE,0) into Beginning_Balance from Daily_Cash_Reconciliation_Sheet where Convert(Entry_Date,Date) = Convert(Previous_Entry_date,Date) and ACC_ID = P_ACCOUNT_ID and Company_ID = P_COMPANY_ID;
         
									else 
											SET User_Entry_Date = Convert(P_ENTRY_DATE,Date);
											select  IFNULL(ENDING_BALANCE,0) into Beginning_Balance from Daily_Cash_Reconciliation_Sheet where Convert(Entry_Date,Date) = Convert(Previous_Entry_date,Date) and Convert(User_Entry_Date,Date)<>Convert(Previous_Entry_Date,Date) and ACC_ID = P_ACCOUNT_ID and Company_ID = P_COMPANY_ID;

									End if;
									
							ELSE
								    SET Closing_Report = 'Not_Allowed';
									SET User_Entry_Date = '';
									SET Previous_Entry_Date = '';
									/*No Records Found*/
							
					END IF;

					select *,Count(*) Over() as Total_ROWS,SUM(A.Amount) Over() as Total_OutFlow,IFNULL(Beginning_Balance,0) as Beginning_Balance,Closing_Report as Closing_Report
					from(
					
							
							
							select 	    
										B.id,
										'Outflow' 		   			as Cash_Flow,
										Round(ABS(B.FORM_AMOUNT),2) as Amount,
										B.FORM_F_ID 	   			as Form_Reference,
										C.RECEIVING_ID 	   			as Form_Id,
										'Payments' 		   			as Confliction_Flag,
										'ReceiveOrder' 	   			as Form_Flag
							from 		Payments A
							inner join 	Payments_Detail B 
							ON 			A.id = B.Payments_Id 
							inner join 	Payments_detail_junction C
							ON 			B.Payments_DETAIL_JUNCTION_ID = C.ID
							where 		A.CASH_ACC_ID 			   = P_ACCOUNT_ID
							And 
											case	
												when Convert(A.PAY_ENTRY_DATE,Date)>Convert(Previous_Entry_Date,Date) then Convert(A.PAY_ENTRY_DATE,Date)>Convert(Previous_Entry_Date,Date)
												when Convert(Previous_Entry_Date,Date) = Convert(User_Entry_Date,Date) then Convert(A.PAY_ENTRY_DATE,Date) = Convert(User_Entry_Date,Date)
											END
							and           
											case 
												when Convert(A.PAY_ENTRY_DATE,Date) <= Convert(User_Entry_Date,Date) then Convert(A.PAY_ENTRY_DATE,Date) <= Convert(User_Entry_Date,Date)
												when Convert(Previous_Entry_Date,Date) = Convert(User_Entry_Date,Date) then Convert(A.PAY_ENTRY_DATE,Date) = Convert(User_Entry_Date,Date)
											END
							and 		 B.FORM_FLAG 			   = 'R'
							and	         A.COMPANY_ID = P_COMPANY_ID
							
							Union All 
							
							select 	    
										B.id,
										'Outflow' 		   as Cash_Flow,
										Round(ABS(B.FORM_AMOUNT),2) as Amount,
										B.FORM_F_ID 	   as Form_Reference,
										C.Sale_Return_ID   as Form_Id,
										'Receipts' 		   as Confliction_Flag,
										'SaleReturn' 	   as Form_Flag
							from 		Receipts A
							inner join 	Receipts_Detail B 
							ON 			A.id = B.Receipts_Id 
							inner join 	Receipts_detail_junction C
							ON 			B.Receipts_DETAIL_JUNCTION_ID = C.ID
							where 		A.CASH_ACC_ID 			   = P_ACCOUNT_ID
							And 
										case	
											when Convert(A.R_ENTRY_DATE,Date)>Convert(Previous_Entry_Date,Date) then Convert(A.R_ENTRY_DATE,Date)>Convert(Previous_Entry_Date,Date)
											when Convert(Previous_Entry_Date,Date) = Convert(User_Entry_Date,Date) then Convert(A.R_ENTRY_DATE,Date) = Convert(User_Entry_Date,Date)
										END
							and           
										case 
											when Convert(A.R_ENTRY_DATE,Date) <= Convert(User_Entry_Date,Date) then Convert(A.R_ENTRY_DATE,Date) <= Convert(User_Entry_Date,Date)
											when Convert(Previous_Entry_Date,Date) = Convert(User_Entry_Date,Date) then Convert(A.R_ENTRY_DATE,Date) = Convert(User_Entry_Date,Date)
										END
							and 		B.FORM_FLAG 			   = 'S'
							and         A.COMPANY_ID = P_COMPANY_ID
							
							Union All 
							
							select 	    
										B.id,
										'Outflow' 		   			as Cash_Flow,
										Round(ABS(B.FORM_AMOUNT),2) as Amount,
										B.FORM_F_ID 	   			as Form_Reference,
										C.Stock_In_ID 	   			as Form_Id,
										'Payments' 		   			as Confliction_Flag,
										'StockIn' 		   			as Form_Flag
							from 		Payments A
							inner join 	Payments_Detail B 
							ON 			A.id = B.Payments_Id 
							inner join 	Payments_detail_junction C
							ON 			B.Payments_DETAIL_JUNCTION_ID = C.ID
							where 		A.CASH_ACC_ID 			   = P_ACCOUNT_ID
							And 
										case	
											when Convert(A.PAY_ENTRY_DATE,Date)>Convert(Previous_Entry_Date,Date) then Convert(A.PAY_ENTRY_DATE,Date)>Convert(Previous_Entry_Date,Date)
											when Convert(Previous_Entry_Date,Date) = Convert(User_Entry_Date,Date) then Convert(A.PAY_ENTRY_DATE,Date) = Convert(User_Entry_Date,Date)
										END
							and           
										case 
											when Convert(A.PAY_ENTRY_DATE,Date) <= Convert(User_Entry_Date,Date) then Convert(A.PAY_ENTRY_DATE,Date) <= Convert(User_Entry_Date,Date)
											when Convert(Previous_Entry_Date,Date) = Convert(User_Entry_Date,Date) then Convert(A.PAY_ENTRY_DATE,Date) = Convert(User_Entry_Date,Date)
										END
							and 		B.FORM_FLAG 			   = 'N'
							and         A.COMPANY_ID = P_COMPANY_ID
							
							Union All 
							
							select 	    
										B.id,
										'Outflow' 					 as Cash_Flow,
										Round(ABS(B.FORM_AMOUNT),2)  as Amount,
										B.FORM_F_ID 				 as Form_Reference,
										C.REPLACEMENT_ID 			 as Form_Id,
										'Receipts' 					 as Confliction_Flag,
										'Replacement' 				 as Form_Flag
							from 		Receipts A
							inner join 	Receipts_Detail B 
							ON 			A.id = B.Receipts_Id 
							inner join 	receipts_detail_junction C
							ON	 		B.RECEIPTS_DETAIL_JUNCTION_ID = C.ID
							where 		A.CASH_ACC_ID 			   = P_ACCOUNT_ID
							And 
										case	
											when Convert(A.R_ENTRY_DATE,Date)>Convert(Previous_Entry_Date,Date) then Convert(A.R_ENTRY_DATE,Date)>Convert(Previous_Entry_Date,Date)
											when Convert(Previous_Entry_Date,Date) = Convert(User_Entry_Date,Date) then Convert(A.R_ENTRY_DATE,Date) = Convert(User_Entry_Date,Date)
										END
							and           
										case 
											when Convert(A.R_ENTRY_DATE,Date) <= Convert(User_Entry_Date,Date) then Convert(A.R_ENTRY_DATE,Date) <= Convert(User_Entry_Date,Date)
											when Convert(Previous_Entry_Date,Date) = Convert(User_Entry_Date,Date) then Convert(A.R_ENTRY_DATE,Date) = Convert(User_Entry_Date,Date)
										END
							and 	    B.FORM_FLAG 			   = 'E'
							and         B.FORM_AMOUNT < 0
							and         A.COMPANY_ID = P_COMPANY_ID
							
							Union All 
							
							select 	    
										B.id,
										'Outflow' 			   			   as Cash_Flow,
										Round(ABS(B.FORM_AMOUNT),2) 	   as Amount,
										B.FORM_F_ID 		   			   as Form_Reference,
										C.PARTIAL_CREDIT_ID    			   as Form_Id,
										'Receipts' 			   			   as Confliction_Flag,
										'PartialCreditVoucher' 			   as Form_Flag
							from 		
										 Receipts A
							inner join 	 Receipts_Detail B 
							ON 			 A.id = B.Receipts_Id 
							inner join	 Receipts_detail_junction C
							ON 			 B.Receipts_DETAIL_JUNCTION_ID = C.ID
							where 		 A.CASH_ACC_ID 			   = P_ACCOUNT_ID
							And 
										case	
											when Convert(A.R_ENTRY_DATE,Date)>Convert(Previous_Entry_Date,Date) then Convert(A.R_ENTRY_DATE,Date)>Convert(Previous_Entry_Date,Date)
											when Convert(Previous_Entry_Date,Date) = Convert(User_Entry_Date,Date) then Convert(A.R_ENTRY_DATE,Date) = Convert(User_Entry_Date,Date)
										END
							and           
										case 
											when Convert(A.R_ENTRY_DATE,Date) <= Convert(User_Entry_Date,Date) then Convert(A.R_ENTRY_DATE,Date) <= Convert(User_Entry_Date,Date)
											when Convert(Previous_Entry_Date,Date) = Convert(User_Entry_Date,Date) then Convert(A.R_ENTRY_DATE,Date) = Convert(User_Entry_Date,Date)
										END
							and 		B.FORM_FLAG 			   = 'L'
							and         A.COMPANY_ID = P_COMPANY_ID
							
					)A Limit P_START,P_LENGTH;
			end if;
				
			
END $$
DELIMITER ;		









































				
                    
					
		
                          
                    
                      
                
