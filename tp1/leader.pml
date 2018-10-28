/* Dolev, Klawe & Rodeh for leader election in unidirectional ring
 * `An O(n log n) unidirectional distributed algorithm for extrema
 * finding in a circle,'  J. of Algs, Vol 3. (1982), pp. 245-260

 */



/* Constantes  */

#define N	5	/* number of processes in the ring */
#define L	10	/* 2xN */

/* Variables globales */

byte I;

byte nr_leaders = 0;

mtype = { one, two, winner };

/* Cannaux  */

 chan q[N] = [L] of { mtype, byte};

/*
* q le nom du cannal
* N si on veut definir un tableau de cannaux de meme taille
* et transmettant les memes types d'elements 
* L la taille du cannal
* { mtype, byte } le type des messages transmis
*/

/* Processus
*
* proctype <nom_proctype>(<paramètres formels>)
* {
*   instructions
* }
*
*/

proctype nnode (chan inp, out; byte mynumber)
{      
       /* Local variables  */
       
        bit Active = 1, know_winner = 0;
	byte nr, maximum = mynumber, neighbourR;

	printf("MSC: %d\n", mynumber);
	out!one(mynumber);
end:	do
	:: inp?one(nr) ->
		if
		:: Active -> 
			if
			:: nr != maximum ->
				out!two(nr);
				neighbourR = nr
			:: else ->
				know_winner = 1;
				out!winner,nr;
			fi
		:: else ->
			out!one(nr)
		fi

	:: inp?two(nr) ->
		if
		:: Active -> 
			if
			:: neighbourR > nr && neighbourR > maximum ->
				maximum = neighbourR;
				out!one(neighbourR)
			:: else ->
				Active = 0
			fi
		:: else ->
			out!two(nr)
		fi
	:: inp?winner,nr ->
		if
		:: nr != mynumber ->
			printf("MSC: LOST\n");
		:: else ->
			printf("MSC: LEADER\n");
			nr_leaders++;
			assert(nr_leaders == 1)
		fi;
		if
		:: know_winner
		:: else -> out!winner,nr
		fi;
		break
	od
/*  si on veut debloquer le processus à la fin
* de 'election
*	do
*         :: skip;
*	od
*/
}

init {
	byte proc;
	byte Ini[6];	/* N<=6 randomize the process numbers */
	atomic {

		I = 1;	/* pick a number to be assigned 1..N */
		do
		:: I <= N ->
			if	/* non-deterministic choice */
			:: Ini[0] == 0 && N >= 1 -> Ini[0] = I
			:: Ini[1] == 0 && N >= 2 -> Ini[1] = I
			:: Ini[2] == 0 && N >= 3 -> Ini[2] = I
			:: Ini[3] == 0 && N >= 4 -> Ini[3] = I
			:: Ini[4] == 0 && N >= 5 -> Ini[4] = I
			:: Ini[5] == 0 && N >= 6 -> Ini[5] = I	/* works for up to N=6 */
			fi;
			I++
		:: I > N ->	/* assigned all numbers 1..N */
			break
		od;

		proc = 1;
		do
		:: proc <= N ->
			run nnode (q[proc-1], q[proc%N], Ini[proc-1]);
			proc++
		:: proc > N -> break
		od
	}
}

/* defining LTL formula 

Unary Operators (unop):
	[]	(the temporal operator always)
	<>	(the temporal operator eventually)
	! 	(the boolean operator for negation)

Binary Operators (binop):
	U 	(the temporal operator strong until)
	W	(the temporal operator weak until
	V 	(the dual of U): (p V q) means !(!p U !q))
	&&	(the boolean operator for logical and)
	||	(the boolean operator for logical or)
	/\	(alternative form of &&)
	\/	(alternative form of ||)
	->	(the boolean operator for logical implication)
	<->	(the boolean operator for logical equivalence)

Inline insertion

            ltl [ name ] '{'  formula '}
*/

/* Examples */

/* sample properties:
 *	<>  elected
 *	<>[]oneLeader
 *	[] (noLeader U oneLeader)
 *	![] noLeader
 *
 * ltl format specifies positive properties
 * that should be satisfied -- spin will
 * look for counter-examples to these properties*/

ltl p0	{ <> (nr_leaders > 2) }
ltl p1	{ <>[] (nr_leaders == 1) }
ltl p2	{ [] (nr_leaders == 0 U nr_leaders == 1) }
ltl p3	{ ![] (nr_leaders == 0) }