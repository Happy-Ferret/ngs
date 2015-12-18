%{
/* Eliminate warnings - start */
#define YY_NO_INPUT
/* Eliminate warnings - end */
#include "ngs.h"
%}

/* TODO: multibyte characters support? */

%option bison-bridge
%option bison-locations
%option reentrant
%option yylineno
%option stack

/* Eliminate warnings - start */
%option nounput
%option noyy_top_state
/* Eliminate warnings - end */

/* TODO: keep track of file name, see http://archive.oreilly.com/pub/a/linux/excerpts/9780596155971/error-reporting-recovery.html */
%{
#define YY_USER_ACTION \
	yylloc->first_line = yylloc->last_line = yylineno; \
	yylloc->first_column = yycolumn; \
	yylloc->last_column = yycolumn + yyleng - 1; \
	yycolumn += yyleng;

#define USE_TEXT_AS_NAME yylval->name = strdup(yytext) /* strdup needed?*/

#define DOLLAR_EXPANSION_END \
		if(YYSTATE == DOLLAR_EXPANSION) {\
			yy_pop_state(yyscanner);\
		}
%}


/* INITIAL is commands */
%x CODE
/* Single quoted string */
%x SQ_STR
/* Double quoted string */
%x DQ_STR
/* Regex (/.../) quoted string */
%x RQ_STR
%x DOLLAR_EXPANSION

whitespace      [ \t]+
identifier		[_a-zA-Z]+[_a-zA-Z0-9]*
digits			[0-9]+

%%

<INITIAL,CODE>^#.*$ { /* ignore comments */ }
<INITIAL>\n         { /* TEMP: ignore newlines for now */ }

<INITIAL>"{"        { yy_push_state(CODE, yyscanner); DEBUG_PARSER("%s", "Entering mode: CODE\n"); return '{'; }

 /* strings */
<INITIAL,CODE>'     { yy_push_state(SQ_STR, yyscanner); DEBUG_PARSER("%s", "Entering mode: SQ_STR\n"); return tSTR_BEGIN; }
<SQ_STR>'           { yy_pop_state(yyscanner); DEBUG_PARSER("%s", "Leaving mode: SQ_STR\n"); return tSTR_END; }
<SQ_STR>[^\']+      { USE_TEXT_AS_NAME; return tSTR_COMP_IMM; }

<INITIAL,CODE>\"    { yy_push_state(DQ_STR, yyscanner); DEBUG_PARSER("%s", "Entering mode: DQ_STR\n"); return tSTR_BEGIN; }
<DQ_STR>\"          { yy_pop_state(yyscanner); DEBUG_PARSER("%s", "Leaving mode: DQ_STR\n"); return tSTR_END; }
<DQ_STR>\$          { yy_push_state(DOLLAR_EXPANSION, yyscanner); DEBUG_PARSER("%s", "Entering mode: DOLLAR_EXPANSION\n");  }
<DQ_STR>[^\"$]+     { USE_TEXT_AS_NAME; return tSTR_COMP_IMM; }

<CODE>{
	[\n]            { DEBUG_PARSER("%s", "LEX NEWLINE\n"); return *yytext; }
	{whitespace}    { /* ignore whitespace */ }
	"+"|"-"|"<"|">"|"is not"|"is"|"not in"|"in" { DEBUG_PARSER("%s", "LEX tBINOP\n"); USE_TEXT_AS_NAME; return tBINOP; }
	"="             { DEBUG_PARSER("%s", "LEX EQUALS\n"); return '='; }
	{digits}		{ yylval->number = atoi(yytext); DEBUG_PARSER("LEX tNUMBER %d\n", yylval->number); return tNUMBER; }
}
<INITIAL,CODE>{
	"END"           { return 0; }
	"null"          { DEBUG_PARSER("%s", "LEX NULL\n"); return tNULL; }
	"true"          { DEBUG_PARSER("%s", "LEX TRUE\n"); return tTRUE; }
	"false"         { DEBUG_PARSER("%s", "LEX FALSE\n"); return tFALSE; }
	"defined"       { DEBUG_PARSER("%s", "LEX tDEFINED\n"); return tDEFINED; }
	"if"            { DEBUG_PARSER("%s", "LEX tIF\n"); return tIF; }
	"while"         { DEBUG_PARSER("%s", "LEX tWHILE\n"); return tWHILE; }
	"for"           { DEBUG_PARSER("%s", "LEX tFOR\n"); return tFOR; }
	"local"         { DEBUG_PARSER("%s", "LEX tLOCAL\n"); return tLOCAL; }
	"F"             { DEBUG_PARSER("LEX F %s\n", yytext); return *yytext; } /* not sure about correctness */
}

<CODE,DOLLAR_EXPANSION>{
	{identifier}    {
		DEBUG_PARSER("LEX tIDENTIFIER %s\n", yytext);
		USE_TEXT_AS_NAME;
		DOLLAR_EXPANSION_END;
		return tIDENTIFIER;
	}
}

<CODE>{
	"."             { DEBUG_PARSER("LEX DOT %s\n", yytext); return *yytext; }
	":="            { DEBUG_PARSER("LEX COLON EQUALS %s\n", yytext); return tCOLONEQ; }
	":"             { DEBUG_PARSER("LEX COLON %s\n", yytext); return *yytext; }
	";"             { DEBUG_PARSER("LEX E.DELIMITER %s\n", yytext); return *yytext; }
	"("|")"         { DEBUG_PARSER("LEX PAREN %s\n", yytext); return *yytext; }
	"["|"]"         { DEBUG_PARSER("LEX BRACKET %s\n", yytext); return *yytext; }
	","             { DEBUG_PARSER("LEX COMMA %s\n", yytext); return *yytext; }
}
<CODE,DOLLAR_EXPANSION>{
	"{"             { yy_push_state(CODE, yyscanner); DEBUG_PARSER("%s", "Entering mode: CODE\n"); return '{'; }
	"}"             {
		yy_pop_state(yyscanner);
		DEBUG_PARSER("%s", "Leaving mode: CODE\n");
		DOLLAR_EXPANSION_END;
		return '}';
	}
}
