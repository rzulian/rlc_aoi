import sys

from rlc import compile, Program, State, compile
import random

def main():
    # load the rl file
    program = compile(["main.rl"])
    # starts a rlc program invoking the user-defined play
    # function and wraps it in object for with some useful methods
    state = program.start()
    output = 'game.log'
    actions = state.legal_actions
    out = open(output, "w+") if output != "-" else sys.stdout



    # invokes directly the user defined function on the real state object
    while program.module.get_current_player(state.state) == -1:
        # enumerate legal actions using the methods defined on the
        # wrapper
        action = random.choice(state.legal_actions)
        state.step(action)


    # checks for termination by using the helper functions
    while not state.is_done():
        state.pretty_print()
        player = state.state.game.state.get_current_player().contents
        print(f"Round: {state.state.game.state.round.value}")
        print(f"coins:{player.coins.value} tools:{player.tools.value} power:{player.powers[0].value}-{player.powers[1].value}-{player.powers[2].value} scholars:{player.scholars_on_hand.value} VP:{player.VP} URP:{player.URP}")
        for num,action in enumerate(state.legal_actions):
            print(f"{num}: {action}")

        print("action num? ")
        decision = input()
        out.write(str(state.legal_actions[int(decision)]) + "\n")
        state.step(state.legal_actions[int(decision)])




    print(f"Your final score is: {player.score(5)}")

if __name__ == "__main__":
    main()