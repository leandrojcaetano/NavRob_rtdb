uses
	rtdb_api;
	var valor:  integer;
	
begin

  if(not (rtdb_api.db_init(0)=0) ) then
  begin
       writeln('Error initialising RTDB');
  end;
	
	read (valor);
	
	DB_put(0, @valor);
	
	DB_free();
end.


//rtdb_api.DB_get(i, GLOBALBALL, @ball_status);

 //rtdb_api.DB_put(ROLEASSIGN, @rAssign);