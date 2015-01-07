unit rtdb_api;

{$link librtdb.a}
{$linklib c}

interface
uses CTypes;

//	*************************
//	DB_init: Aloca acesso a base de dados
//
//	Saida:
//		0 = OK
//		-1 = erro
//
//      int DB_init (void);
function DB_init(agentNumber: integer): integer; cdecl; external;

//	*************************
//	DB_free: Liberta acesso a base de dados
//
//void DB_free (void);

procedure DB_free; cdecl; external;


//	*************************
//	DB_put: Escreve na base de dados do proprio agente
//
//	Entrada:
//		int _id = identificador da 'variavel'
//		void *_value = ponteiro com os dados
//	Saida:
//		0 = OK
//		-1 = erro
//
//int DB_put (int _id, void *_value);

function DB_put(_id: integer; _value: pointer): integer; cdecl; external;


//	*************************
//	DB_get: Le da base de dados
//
//	Entrada:
//		int _agent = numero do agente
//		int _id = identificador da 'variavel'
//		void *_value = ponteiro para onde sao copiados os dados
//	Saida:
//		int life = tempo de vida da 'variavel' em ms
//			-1 se erro
//
// int DB_get (int _from_agent, int _id, void *_value);

function DB_get(_from_agent: integer; _id: integer; _value: pointer): integer; cdecl; external;

//	*************************
//	Whoami: identifica o agente onde esta a correr
//
//	Saida:
//		int agent_number = numero do agente
//
//int Whoami(void);

function Whoami: integer; cdecl; external;


implementation

end.

