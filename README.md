# Tuolaji on the Internet Computer

A Motoko canister that hosts the backend of https://tuolaji.online — a four-seat,
partnership, trick-taking card game. One canister hosts many independent tables
and is the sole rule authority: clients send commands and read a caller-scoped
view, and the server validates every move.

The official repository is now at https://github.com/Tuolaji-Online/tuolaji.
