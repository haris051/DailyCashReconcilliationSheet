Alter Table Company
Add Account_Id int;

update Company A 
inner join accounts_id B 
on A.id = B.Company_Id 
SET A.Account_Id = B.id 
where B.ACC_ID = 1020;

Alter Table Company 
Modify Account_ID int not null;

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
					select Entry_Date into Is_ENTRY_Date_Exists from Daily_Cash_Reconciliation_Sheet where Entry_Date = P_ENTRY_DATE and ACC_ID = P_ACCOUNT_ID and Company_ID = P_COMPANY_ID;
					select ENDING_BALANCE into Beginning_Balance from  Daily_Cash_Reconciliation_Sheet where Convert(Entry_Date,Date) = Convert(Previous_Entry_date,Date);
					
					
					if Last_Entry_Date is null OR Last_Entry_Date = '' and Is_ENTRY_Date_Exists = '' OR IS_ENTRY_DATE_EXISTS is null
							then 
								SET User_Entry_Date = Convert(P_ENTRY_DATE,Date);
								SET Previous_Entry_Date = Convert(P_ENTRY_DATE,Date);
								SET Closing_Report = 'Allowed';
								ELSEIF Convert(P_ENTRY_DATE,Date) > Convert(Last_Entry_Date,Date) and Is_ENTRY_Date_Exists = ''
								then 
									
									SET User_Entry_Date = Convert(P_ENTRY_DATE,Date);
									SET Previous_Entry_Date = Convert(Last_Entry_Date,Date);
									Set Closing_Report = 'Allowed';
							
								ELSEif Convert(P_ENTRY_DATE,Date) <= Convert(Last_Entry_Date,Date) and Is_ENTRY_Date_Exists <> ''
								then 
									
									select MAX(ENTRY_DATE) into Previous_Entry_Date from Daily_Cash_Reconciliation_Sheet where ENTRY_DATE < Convert(P_ENTRY_DATE,Date) and ACC_ID = P_ACCOUNT_ID and Company_ID = P_COMPANY_ID;
									Set Closing_Report = 'Not_Allowed';
                                    					/*IF Entry Date is First Entry Date*/
                                    					if Previous_Entry_Date is null or Previous_Entry_Date = ''
										then 
                                        
											SET User_Entry_Date = Convert(P_ENTRY_DATE,Date);
										        SET Previous_Entry_Date = Convert(P_ENTRY_DATE,Date);
                                            
									else 
											SET User_Entry_Date = Convert(P_ENTRY_DATE,Date);
                                            
									End if;
						
							ELSE
                                    					Set Closing_Report = 'Not_Allowed';
									SET User_Entry_Date = '';
									SET Previous_Entry_Date = '';
							    /*No Records Found*/
							
					END IF;
							
						
							    select ENDING_BALANCE into Beginning_Balance from	Daily_Cash_Reconciliation_Sheet	where Convert(Entry_Date,Date) = Convert(Previous_Entry_date,Date) and Convert(User_Entry_Date,Date)<>Convert(Previous_Entry_Date,Date);

								select *,Count(*) Over() as Total_ROWS,SUM(A.Amount) Over() as Total_InFlow,IFNULL(Beginning_Balance,0) as Beginning_Balance,Closing_Report as Closing_Report
                                from(
										select      '-1' as id,
													'inflow' as Cash_Flow,
													case when ENDING_BALANCE > 0 then ENDING_BALANCE else 0 end as Amount,
													'' as Form_Reference,
													'' as Form_Id,
													'' as Confliction_Flag,
													'Beginning Balance' as Form_Flag
										from 
													Daily_Cash_Reconciliation_Sheet
										where 
													Convert(Entry_Date,Date) = Convert(Previous_Entry_date,Date)
										AND 
													ENDING_BALANCE > 0
										and 			Convert(User_Entry_Date,Date)	<>	Convert(Previous_Entry_Date,Date)
													
										Union All
										            
										select 	    
													B.id,
													'Inflow' 			as Cash_Flow,
													 ABS(B.FORM_AMOUNT) as Amount,
													 B.FORM_F_ID 		as Form_Reference,
													 C.REPLACEMENT_ID 	as Form_Id,
													 'Receipts' 		as Confliction_Flag,
													 'Replacement' 		as FORM_FLAG
										from 		  
													  Receipts A
										inner join	 	  Receipts_Detail B 
										ON 			  A.id = B.Receipts_Id 
										inner join 		  receipts_detail_junction C
										ON 			  B.RECEIPTS_DETAIL_JUNCTION_ID = C.ID
										where 		  	  A.CASH_ACC_ID 			    = P_ACCOUNT_ID
                                    					        And 
													  case	
															when Convert(A.ENTRY_DATE,Date)>Convert(Previous_Entry_Date,Date) then Convert(A.ENTRY_DATE,Date)>Convert(Previous_Entry_Date,Date)
                                                            								when Convert(Previous_Entry_Date,Date) = Convert(User_Entry_Date,Date) then Convert(A.Entry_Date,Date) = Convert(User_Entry_Date,Date)
													  END
										and           
													  case 
															when Convert(A.Entry_Date,Date) <= Convert(User_Entry_Date,Date) then Convert(A.Entry_date,Date) <= Convert(User_Entry_Date,Date)
															when Convert(Previous_Entry_Date,Date) = Convert(User_Entry_Date,Date) then Convert(A.Entry_Date,Date) = Convert(User_Entry_Date,Date)
													  END
                                        					and   	      B.FORM_FLAG 			        = 'E'
										and           B.FORM_AMOUNT > 0
										and           A.COMPANY_ID = P_COMPANY_ID
										
										Union All 
										
										select  	
													   B.id,
													  'Inflow' 				as Cash_Flow,
													   ABS(B.FORM_AMOUNT) 	as Amount,
													   B.FORM_F_ID 			as Form_Reference,
													   C.Sale_INVOICE_ID 	as Form_Id,
													   'Receipts' 			as Confliction_Flag,
													   'SaleInvoice' 		as Form_Flag
										from 	
												Receipts A 
										inner join  	receipts_detail B 
										ON    	        A.id = B.RECEIPTS_ID
										inner join  	Receipts_Detail_Junction C 
										ON    	        B.RECEIPTS_DETAIL_JUNCTION_ID = C.ID
										where   	A.CASH_ACC_ID = P_ACCOUNT_ID
										And 
													  case	
															when Convert(A.ENTRY_DATE,Date)>Convert(Previous_Entry_Date,Date) then Convert(A.ENTRY_DATE,Date)>Convert(Previous_Entry_Date,Date)
                                                            								when Convert(Previous_Entry_Date,Date) = Convert(User_Entry_Date,Date) then Convert(A.Entry_Date,Date) = Convert(User_Entry_Date,Date)
													  END
										and           
													  case 
															when Convert(A.Entry_Date,Date) <= Convert(User_Entry_Date,Date) then Convert(A.Entry_date,Date) <= Convert(User_Entry_Date,Date)
															when Convert(Previous_Entry_Date,Date) = Convert(User_Entry_Date,Date) then Convert(A.Entry_Date,Date) = Convert(User_Entry_Date,Date)
													  END		   
										and		        		B.FORM_FLAG = 'I'
										and    	        			A.COMPANY_ID = P_COMPANY_ID
										
										Union All 
										
										select  	
														B.id,
														'Inflow' 			 as Cash_Flow,
														ABS(B.FORM_AMOUNT) 	 as Amount,
														B.FORM_F_ID 		 as Form_Reference,
														C.STOCK_TRANSFER_ID  as Form_Id,
														'Receipts'			 as Confliction_Flag,
														'StockTransfer' 	 as Form_Flag
										from 	
														Receipts A 
										inner join 	    		receipts_detail B 
										ON     		   		A.id = B.RECEIPTS_ID
										inner join  			Receipts_Detail_Junction C 
										ON     		    		B.RECEIPTS_DETAIL_JUNCTION_ID = C.ID
										where     			A.CASH_ACC_ID = P_ACCOUNT_ID
										And 
													  case	
															when Convert(A.ENTRY_DATE,Date)>Convert(Previous_Entry_Date,Date) then Convert(A.ENTRY_DATE,Date)>Convert(Previous_Entry_Date,Date)
                                                            								when Convert(Previous_Entry_Date,Date) = Convert(User_Entry_Date,Date) then Convert(A.Entry_Date,Date) = Convert(User_Entry_Date,Date)
													  END
										and           
													  case 
															when Convert(A.Entry_Date,Date) <= Convert(User_Entry_Date,Date) then Convert(A.Entry_date,Date) <= Convert(User_Entry_Date,Date)
															when Convert(Previous_Entry_Date,Date) = Convert(User_Entry_Date,Date) then Convert(A.Entry_Date,Date) = Convert(User_Entry_Date,Date)
													  END
										and     	    B.FORM_FLAG = 'T'
										and    		    A.COMPANY_ID = P_COMPANY_ID
										
										Union All 
										
										select  	
												    B.id,
												    'Inflow' 	    	as Cash_Flow,
												    ABS(B.FORM_AMOUNT)  as Amount,
												    B.FORM_F_ID 	as Form_Reference,
												    C.VCM_ID 	    	as Form_Id,
												    'Payments' 	    	as Confliction_Flag,
												    'VendorCreditMemo'  as Form_Flag
										from 	
												    Payments A 
										inner join 	    Payments_detail B 
										ON    		    A.id = B.Payments_ID
										inner join 	    Payments_Detail_Junction C 
										ON         	    B.Payments_DETAIL_JUNCTION_ID = C.ID
										where    	    A.CASH_ACC_ID = P_ACCOUNT_ID
										And 
													  case	
															when Convert(A.ENTRY_DATE,Date)>Convert(Previous_Entry_Date,Date) then Convert(A.ENTRY_DATE,Date)>Convert(Previous_Entry_Date,Date)
                                                            								when Convert(Previous_Entry_Date,Date) = Convert(User_Entry_Date,Date) then Convert(A.Entry_Date,Date) = Convert(User_Entry_Date,Date)
													  END
										and           
													  case 
															when Convert(A.Entry_Date,Date) <= Convert(User_Entry_Date,Date) then Convert(A.Entry_date,Date) <= Convert(User_Entry_Date,Date)
															when Convert(Previous_Entry_Date,Date) = Convert(User_Entry_Date,Date) then Convert(A.Entry_Date,Date) = Convert(User_Entry_Date,Date)
													  END
										and      	    B.FORM_FLAG = 'V'
										and      	    A.COMPANY_ID = P_COMPANY_ID
						
										Union All 
										
										select  	
												B.id,
												'Inflow' 		as Cash_Flow,
												ABS(B.FORM_AMOUNT) 	as Amount,
												B.FORM_F_ID 		as Form_Reference,
												C.PARTIAL_CREDIT_ID     as Form_Id,
												'Payments' 		as Confliction_Flag,
												'PartialCreditVoucher'  as Form_Flag
										from 	
												Payments A 
										inner join  	Payments_detail B 
										ON          	A.id = B.Payments_ID
										inner join 	Payments_Detail_Junction C 
										ON         	B.Payments_DETAIL_JUNCTION_ID = C.ID
										where   	A.CASH_ACC_ID = P_ACCOUNT_ID
										And 
													  case	
															when Convert(A.ENTRY_DATE,Date)>Convert(Previous_Entry_Date,Date) then Convert(A.ENTRY_DATE,Date)>Convert(Previous_Entry_Date,Date)
                                                            								when Convert(Previous_Entry_Date,Date) = Convert(User_Entry_Date,Date) then Convert(A.Entry_Date,Date) = Convert(User_Entry_Date,Date)
													  END
										and           
													  case 
															when Convert(A.Entry_Date,Date) <= Convert(User_Entry_Date,Date) then Convert(A.Entry_date,Date) <= Convert(User_Entry_Date,Date)
															when Convert(Previous_Entry_Date,Date) = Convert(User_Entry_Date,Date) then Convert(A.Entry_Date,Date) = Convert(User_Entry_Date,Date)
													  END
										and       	    B.FORM_FLAG = 'L'
										and      	    A.COMPANY_ID = P_COMPANY_ID
								)A Limit P_START,P_LENGTH;
								
			
			end if;
			
			if (P_Flow_Flag = "OutFlow")
			then 
					select MAX(ENTRY_DATE) into Last_Entry_Date from Daily_Cash_Reconciliation_Sheet where ACC_ID = P_ACCOUNT_ID and Company_ID = P_COMPANY_ID;
					select Entry_Date into Is_ENTRY_Date_Exists from Daily_Cash_Reconciliation_Sheet where Entry_Date = P_ENTRY_DATE and ACC_ID = P_ACCOUNT_ID and Company_ID = P_COMPANY_ID;

					
					
					if Last_Entry_Date is null OR Last_Entry_Date = '' and Is_ENTRY_Date_Exists = ''
							then 
							
								SET User_Entry_Date = Convert(P_ENTRY_DATE,Date);
								SET Previous_Entry_Date = Convert(P_ENTRY_DATE,Date);
							    SET Closing_Report = 'Allowed';
                                
								ELSEIF Convert(P_ENTRY_DATE,Date) > Convert(Last_Entry_Date,Date) and Is_ENTRY_Date_Exists = ''
								then 
									
									SET User_Entry_Date = Convert(P_ENTRY_DATE,Date);
									SET Previous_Entry_Date = Convert(Last_Entry_Date,Date);
									SET Closing_Report = 'Allowed';
							
								ELSEif Convert(P_ENTRY_DATE,Date) <= Convert(Last_Entry_Date,Date) and Is_ENTRY_Date_Exists <> ''
								then 
									
                                    					Set Closing_Report = 'Not_Allowed';
									select MAX(ENTRY_DATE) into Previous_Entry_Date from Daily_Cash_Reconciliation_Sheet where ENTRY_DATE < Convert(P_ENTRY_DATE,Date) and ACC_ID = P_ACCOUNT_ID and Company_ID = P_COMPANY_ID;
									/*IF Entry Date is First Entry Date*/
                                    					if Previous_Entry_Date is null or Previous_Entry_Date = ''
										then 
                                        
											SET User_Entry_Date = Convert(P_ENTRY_DATE,Date);
										        SET Previous_Entry_Date = Convert(P_ENTRY_DATE,Date);
                                            
									else 
											SET User_Entry_Date = Convert(P_ENTRY_DATE,Date);
                                            
									End if;
									
							ELSE
								    	SET Closing_Report = 'Not_Allowed';
									SET User_Entry_Date = '';
									SET Previous_Entry_Date = '';
							    /*No Records Found*/
							
					END IF;
					select  ENDING_BALANCE into Beginning_Balance from	Daily_Cash_Reconciliation_Sheet	where Convert(Entry_Date,Date) = Convert(Previous_Entry_date,Date) and Convert(User_Entry_Date,Date)<>Convert(Previous_Entry_Date,Date);

					select *,Count(*) Over() as Total_ROWS,SUM(A.Amount) Over() as Total_OutFlow,IFNULL(Beginning_Balance,0) as Beginning_Balance,Closing_Report as Closing_Report
					from(
					
							select    	'-1' 		as id,
									  'Outflow'	as Cash_Flow,
									  case when ENDING_BALANCE < 0 then ABS(ENDING_BALANCE) else 0 end as Amount,
									  '' 		as Form_Reference,
									  '' 		as Form_Id,
									  '' 		as Confliction_Flag,
									  'Beginning Balance' as Form_Flag
							from 
									  Daily_Cash_Reconciliation_Sheet
							where 
									  Convert(Entry_Date,Date) = Convert(Previous_Entry_date,Date)
							AND 
									  ENDING_BALANCE < 0
							and 
									  Convert(User_Entry_Date,Date)	<>	Convert(Previous_Entry_Date,Date)
                            
							Union All
							
							select 	    
										B.id,
										'Outflow' 		   as Cash_Flow,
										ABS(B.FORM_AMOUNT) as Amount,
										B.FORM_F_ID 	   as Form_Reference,
										C.RECEIVING_ID 	   as Form_Id,
										'Payments' 		   as Confliction_Flag,
										'ReceiveOrder' 	   as Form_Flag
							from 			Payments A
							inner join 		Payments_Detail B 
							ON 			A.id = B.Payments_Id 
							inner join 		Payments_detail_junction C
							ON 			B.Payments_DETAIL_JUNCTION_ID = C.ID
							where 			A.CASH_ACC_ID 			   = P_ACCOUNT_ID
							And 
													  case	
															when Convert(A.ENTRY_DATE,Date)>Convert(Previous_Entry_Date,Date) then Convert(A.ENTRY_DATE,Date)>Convert(Previous_Entry_Date,Date)
                                                            								when Convert(Previous_Entry_Date,Date) = Convert(User_Entry_Date,Date) then Convert(A.Entry_Date,Date) = Convert(User_Entry_Date,Date)
													  END
							and           
													  case 
															when Convert(A.Entry_Date,Date) <= Convert(User_Entry_Date,Date) then Convert(A.Entry_date,Date) <= Convert(User_Entry_Date,Date)
															when Convert(Previous_Entry_Date,Date) = Convert(User_Entry_Date,Date) then Convert(A.Entry_Date,Date) = Convert(User_Entry_Date,Date)
													  END
							and 		 B.FORM_FLAG 			   = 'R'
							and	         A.COMPANY_ID = P_COMPANY_ID
							
							Union All 
							
							select 	    
										B.id,
										'Outflow' 		   as Cash_Flow,
										ABS(B.FORM_AMOUNT) as Amount,
										B.FORM_F_ID 	   as Form_Reference,
										C.Sale_Return_ID   as Form_Id,
										'Receipts' 		   as Confliction_Flag,
										'SaleReturn' 	   as Form_Flag
							from 			Receipts A
							inner join 		Receipts_Detail B 
							ON 			A.id = B.Receipts_Id 
							inner join 		Receipts_detail_junction C
							ON 			B.Receipts_DETAIL_JUNCTION_ID = C.ID
							where 			A.CASH_ACC_ID 			   = P_ACCOUNT_ID
							And 
													  case	
															when Convert(A.ENTRY_DATE,Date)>Convert(Previous_Entry_Date,Date) then Convert(A.ENTRY_DATE,Date)>Convert(Previous_Entry_Date,Date)
                                                            								when Convert(Previous_Entry_Date,Date) = Convert(User_Entry_Date,Date) then Convert(A.Entry_Date,Date) = Convert(User_Entry_Date,Date)
													  END
										and           
													  case 
															when Convert(A.Entry_Date,Date) <= Convert(User_Entry_Date,Date) then Convert(A.Entry_date,Date) <= Convert(User_Entry_Date,Date)
															when Convert(Previous_Entry_Date,Date) = Convert(User_Entry_Date,Date) then Convert(A.Entry_Date,Date) = Convert(User_Entry_Date,Date)
													  END
							and 		B.FORM_FLAG 			   = 'S'
							and             A.COMPANY_ID = P_COMPANY_ID
							
							Union All 
							
							select 	    
										B.id,
										'Outflow' 		   as Cash_Flow,
										ABS(B.FORM_AMOUNT) as Amount,
										B.FORM_F_ID 	   as Form_Reference,
										C.Stock_In_ID 	   as Form_Id,
										'Payments' 		   as Confliction_Flag,
										'StockIn' 		   as Form_Flag
							from 			Payments A
							inner join 		Payments_Detail B 
							ON 			A.id = B.Payments_Id 
							inner join 		Payments_detail_junction C
							ON 			B.Payments_DETAIL_JUNCTION_ID = C.ID
							where 			A.CASH_ACC_ID 			   = P_ACCOUNT_ID
							And 
													  case	
															when Convert(A.ENTRY_DATE,Date)>Convert(Previous_Entry_Date,Date) then Convert(A.ENTRY_DATE,Date)>Convert(Previous_Entry_Date,Date)
                                                            								when Convert(Previous_Entry_Date,Date) = Convert(User_Entry_Date,Date) then Convert(A.Entry_Date,Date) = Convert(User_Entry_Date,Date)
													  END
										and           
													  case 
															when Convert(A.Entry_Date,Date) <= Convert(User_Entry_Date,Date) then Convert(A.Entry_date,Date) <= Convert(User_Entry_Date,Date)
															when Convert(Previous_Entry_Date,Date) = Convert(User_Entry_Date,Date) then Convert(A.Entry_Date,Date) = Convert(User_Entry_Date,Date)
													  END
							and 		B.FORM_FLAG 			   = 'N'
							and         	A.COMPANY_ID = P_COMPANY_ID
							
							Union All 
							
							select 	    
										B.id,
										'Outflow' 			as Cash_Flow,
										ABS(B.FORM_AMOUNT)  as Amount,
										B.FORM_F_ID 		as Form_Reference,
										C.REPLACEMENT_ID 	as Form_Id,
										'Receipts' 			as Confliction_Flag,
										'Replacement' 		as Form_Flag
							from 			Receipts A
							inner join 		Receipts_Detail B 
							ON 			A.id = B.Receipts_Id 
							inner join 		receipts_detail_junction C
							ON	 		B.RECEIPTS_DETAIL_JUNCTION_ID = C.ID
							where 			A.CASH_ACC_ID 			   = P_ACCOUNT_ID
							And 
													  case	
															when Convert(A.ENTRY_DATE,Date)>Convert(Previous_Entry_Date,Date) then Convert(A.ENTRY_DATE,Date)>Convert(Previous_Entry_Date,Date)
                                                            								when Convert(Previous_Entry_Date,Date) = Convert(User_Entry_Date,Date) then Convert(A.Entry_Date,Date) = Convert(User_Entry_Date,Date)
													  END
										and           
													  case 
															when Convert(A.Entry_Date,Date) <= Convert(User_Entry_Date,Date) then Convert(A.Entry_date,Date) <= Convert(User_Entry_Date,Date)
															when Convert(Previous_Entry_Date,Date) = Convert(User_Entry_Date,Date) then Convert(A.Entry_Date,Date) = Convert(User_Entry_Date,Date)
													  END
							and 	    B.FORM_FLAG 			   = 'E'
							and         B.FORM_AMOUNT < 0
							and         A.COMPANY_ID = P_COMPANY_ID
							
							Union All 
							
							select 	    
										B.id,
										'Outflow' 			   as Cash_Flow,
										ABS(B.FORM_AMOUNT) 	   as Amount,
										B.FORM_F_ID 		   as Form_Reference,
										C.PARTIAL_CREDIT_ID    as Form_Id,
										'Receipts' 			   as Confliction_Flag,
										'PartialCreditVoucher' as Form_Flag
							from 		
										 Receipts A
							inner join 		 Receipts_Detail B 
							ON 			 A.id = B.Receipts_Id 
							inner join		 Receipts_detail_junction C
							ON 			 B.Receipts_DETAIL_JUNCTION_ID = C.ID
							where 		 	A.CASH_ACC_ID 			   = P_ACCOUNT_ID
							And 
													  case	
															when Convert(A.ENTRY_DATE,Date)>Convert(Previous_Entry_Date,Date) then Convert(A.ENTRY_DATE,Date)>Convert(Previous_Entry_Date,Date)
                                                            								when Convert(Previous_Entry_Date,Date) = Convert(User_Entry_Date,Date) then Convert(A.Entry_Date,Date) = Convert(User_Entry_Date,Date)
													  END
										and           
													  case 
															when Convert(A.Entry_Date,Date) <= Convert(User_Entry_Date,Date) then Convert(A.Entry_date,Date) <= Convert(User_Entry_Date,Date)
															when Convert(Previous_Entry_Date,Date) = Convert(User_Entry_Date,Date) then Convert(A.Entry_Date,Date) = Convert(User_Entry_Date,Date)
													  END
							and 		 B.FORM_FLAG 			   = 'L'
							and         A.COMPANY_ID = P_COMPANY_ID
							
					)A Limit P_START,P_LENGTH;
			end if;
				
			
END $$
DELIMITER ;	










































				
                    
					
		
                          
                    
                      
                
