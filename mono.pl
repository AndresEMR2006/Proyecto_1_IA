% ============================================================
%  PROBLEMA DEL MONO Y EL PLÁTANO
%  Búsqueda: Amplitud con TopHeurística
%  Estado: state(MonkeyPos, MonkeyHeight, BoxPos, BananaState)
% ============================================================

% --- ESTADO INICIAL Y META ---

estado_inicial(state(door, onfloor, window, hasnot)).

es_meta(state(_, _, _, has)).

% ============================================================
%  OPERADORES
% ============================================================

% 1. Caminar (mono en piso, cambia de posición)
mover(state(Pos, onfloor, BoxPos, Ban),
      state(Pos2, onfloor, BoxPos, Ban),
      walk(Pos, Pos2)) :-
    member(Pos2, [door, window, middle]),
    Pos2 \= Pos.

% 2. Empujar caja (mono en piso, en la misma posición que la caja)
mover(state(Pos, onfloor, Pos, Ban),
      state(Pos2, onfloor, Pos2, Ban),
      push(Pos, Pos2)) :-
    member(Pos2, [door, window, middle]),
    Pos2 \= Pos.

% 3. Subir a la caja (mono en piso, en la misma posición que la caja)
mover(state(Pos, onfloor, Pos, Ban),
      state(Pos, onbox, Pos, Ban),
      climb).

% 4. Agarrar el plátano (mono sobre la caja en el centro)
mover(state(middle, onbox, middle, hasnot),
      state(middle, onbox, middle, has),
      grasp).

% ============================================================
%  FUNCIÓN HEURÍSTICA
%  Mayor valor = mejor estado (más cercano a la meta)
% ============================================================

heuristica(state(_, _, _, has), 4).                        % Tiene el plátano: meta
heuristica(state(middle, onbox, middle, hasnot), 3).       % Listo para agarrar
heuristica(state(middle, onfloor, middle, hasnot), 2).     % Mono y caja bajo plátano
heuristica(state(_, onfloor, middle, hasnot), 1).          % La caja está en middle
heuristica(_, 0).                                          % Cualquier otro estado

% ============================================================
%  AUXILIARES
% ============================================================

% Verifica si un estado ya está en la lista de abiertos
miembro_estado(E, [nodo(E, _)|_]).
miembro_estado(E, [_|R]) :- miembro_estado(E, R).

% Selecciona el hijo con mayor heurística; los demás quedan en orden original
seleccionar_mejor([H], H, []) :- !.
seleccionar_mejor([H|T], Mejor, Resto) :-
    seleccionar_mejor_aux(T, H, Mejor, Resto).

seleccionar_mejor_aux([], MejorAct, MejorAct, []).
seleccionar_mejor_aux([H|T], MejorAct, Mejor, [H|Resto]) :-
    H = hijo(_, _, Hv),
    MejorAct = hijo(_, _, HvA),
    Hv =< HvA, !,
    seleccionar_mejor_aux(T, MejorAct, Mejor, Resto).
seleccionar_mejor_aux([H|T], MejorAct, Mejor, [MejorAct|Resto]) :-
    H = hijo(_, _, Hv),
    MejorAct = hijo(_, _, HvA),
    Hv > HvA,
    seleccionar_mejor_aux(T, H, Mejor, Resto).

% Ordena la lista de hijos según TopHeurística:
% el mejor va primero, los demás en su orden original
ordenar_hijos_topH([], []) :- !.
ordenar_hijos_topH([H], [H]) :- !.
ordenar_hijos_topH(Hijos, [Mejor|Otros]) :-
    seleccionar_mejor(Hijos, Mejor, Otros).

% Inserta los hijos ordenados al FINAL de la cola (FIFO = BFS)
insertar_hijos_cola([], _, Cola, Cola).
insertar_hijos_cola([hijo(Eh, Accion, _)|T], CaminoPadre, Cola, NuevaCola) :-
    append(CaminoPadre, [Accion], CaminoHijo),
    append(Cola, [nodo(Eh, CaminoHijo)], Cola2),
    insertar_hijos_cola(T, CaminoPadre, Cola2, NuevaCola).

% ============================================================
%  BÚSQUEDA: AMPLITUD CON TOPHEURÍSTICA
% ============================================================

% Caso base: el nodo al frente de la cola es la meta
bfs_topH([nodo(E, Camino)|_], _, Camino) :-
    es_meta(E), !.

% Caso recursivo: expandir el nodo al frente
bfs_topH([nodo(E, Camino)|RestoCola], Cerrados, CaminoSol) :-
    % Generar hijos válidos (no visitados ni en cola)
    findall(
        hijo(Eh, Accion, Hv),
        (   mover(E, Eh, Accion),
            \+ member(Eh, Cerrados),
            \+ miembro_estado(Eh, RestoCola),
            heuristica(Eh, Hv)
        ),
        Hijos
    ),
    % Ordenar: el hijo con mayor h va primero
    ordenar_hijos_topH(Hijos, HijosOrdenados),
    % Insertar hijos al final de la cola
    insertar_hijos_cola(HijosOrdenados, Camino, RestoCola, NuevaCola),
    % Marcar estado actual como cerrado y continuar
    bfs_topH(NuevaCola, [E|Cerrados], CaminoSol).

% Sin solución
bfs_topH([], _, _) :-
    write('No se encontró solución.'), nl, fail.

% ============================================================
%  PUNTO DE ENTRADA
% ============================================================

resolver(Camino) :-
    estado_inicial(E0),
    bfs_topH([nodo(E0, [])], [], Camino).

% Imprime la solución paso a paso
resolver_e_imprimir :-
    (   resolver(Camino)
    ->  length(Camino, N),
        format("Solución encontrada en ~w pasos:~n", [N]),
        imprimir_pasos(Camino, 1)
    ;   write('No se encontró solución.')
    ).

imprimir_pasos([], _).
imprimir_pasos([Accion|Resto], N) :-
    format("  Paso ~w: ~w~n", [N, Accion]),
    N1 is N + 1,
    imprimir_pasos(Resto, N1).
