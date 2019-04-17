// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT license.

//////////////////////////////////////////////////////////////////////
// This file contains testing harness for all tasks.
// You should not modify anything in this file.
// The tasks themselves can be found in Tasks.qs file.
//////////////////////////////////////////////////////////////////////

namespace Quantum.Kata.GHZGame {

    open Microsoft.Quantum.Primitive;
    open Microsoft.Quantum.Canon;
    open Microsoft.Quantum.Extensions.Convert;
    open Microsoft.Quantum.Extensions.Testing;

    // All possible starting bits (r, s and t) that the referee can give
    // to Alice, Bob and Charlie.
    function RefereeBits () : Bool[][] {
        return [[false, false, false],
                [true, true, false],
                [false, true, true],
                [true, false, true]];
    }

    operation T11_WinCondition_Test () : Unit {
        for (rst in RefereeBits()) {
            for (i in 0..1 <<< 3 - 1) {
                let abc = BoolArrFromPositiveInt(i, 3);
                AssertBoolEqual(
                    WinCondition(rst, abc),
                    WinCondition_Reference(rst, abc),
                    $"Win condition is wrong for rst={rst}, abc={abc}");
            }
        }
    }


    // ------------------------------------------------------
    operation GetClassicalStrategySuccessRate (N : Int, strategy : (Bool => Bool)) : Double {
        let inputs = RefereeBits();
        mutable wins = 0;
        for (i in 0..N - 1) {
            let rst = inputs[RandomInt(Length(inputs))];
            let abc = PlayClassicalGHZ_Reference(strategy, rst);
            if (WinCondition_Reference(rst, abc)) {
                set wins = wins + 1;
            }
        }
        return ToDouble(wins) / ToDouble(N);
    }

    operation T12_RandomClassical_Test () : Unit {
        AssertAlmostEqualTol(GetClassicalStrategySuccessRate(10000, RandomClassicalStrategy), 0.5, 0.02);
    }


    // ------------------------------------------------------
    operation T13_BestClassical_Test () : Unit {
        AssertAlmostEqualTol(GetClassicalStrategySuccessRate(10000, BestClassicalStrategy), 0.75, 0.02);
    }


    // ------------------------------------------------------
    operation TestStrategy (input : Bool, mode : Int) : Bool {
        return mode == 0 ? false | mode == 1 ? true | mode == 2 ? input | not input;
    }


    operation T14_PlayClassicalGHZ_Test () : Unit {
        // To test the interaction, run it on several deterministic strategies (not necessarily good ones)
        let inputs = RefereeBits();
        for (rst in inputs) {
            for (mode in 0..3) {
                let result = PlayClassicalGHZ(TestStrategy(_, mode), rst);
                let expected = PlayClassicalGHZ_Reference(TestStrategy(_, mode), rst);
                AssertBoolArrayEqual(result, expected, $"Unexpected result for rst={rst}");
            }
        }
    }

    //////////////////////////////////////////////////////////////////
    // Part II. Quantum GHZ
    //////////////////////////////////////////////////////////////////

    operation AssertEqualOnZeroState (N : Int, taskImpl : (Qubit[] => Unit), refImpl : (Qubit[] => Unit : Adjoint)) : Unit {
        using (qs = Qubit[N]) {
            // apply operation that needs to be tested
            taskImpl(qs);
            
            // apply adjoint reference operation and check that the result is |0ᴺ⟩
            Adjoint refImpl(qs);
            
            // assert that all qubits end up in |0⟩ state
            AssertAllZero(qs);
        }
    }

    operation T21_CreateEntangledTriple_Test () : Unit {
        AssertEqualOnZeroState(3, CreateEntangledTriple, CreateEntangledTriple_Reference);
    }


    // ------------------------------------------------------
    operation T22_QuantumStrategy_Test () : Unit {
        using (q = Qubit()) {
            AssertBoolEqual(QuantumStrategy(false, q), false, "|0⟩ not measured as false");
            Reset(q);

            X(q);
            AssertBoolEqual(QuantumStrategy(false, q), true, "|1⟩ not measured as true");
            Reset(q);

            H(q);
            AssertBoolEqual(QuantumStrategy(true, q), false, "|+⟩ is not measured as false");
            Reset(q);

            X(q);
            H(q);
            AssertBoolEqual(QuantumStrategy(true, q), true, "|-⟩ is not measured as true");
            Reset(q);
        }
    }


    // ------------------------------------------------------
    operation T23_PlayQuantumGHZ_Test () : Unit {
        for (i in 0..1000) {
            let rst = (RefereeBits())[RandomInt(Length(RefereeBits()))];
            let strategies = [QuantumStrategy(rst[0], _), QuantumStrategy(rst[1], _), QuantumStrategy(rst[2], _)];
            let abc = PlayQuantumGHZ(strategies);
            AssertBoolEqual(WinCondition_Reference(rst, abc), true,
                            $"Quantum strategy lost: for rst={rst} the players returned abc={abc}");
        }
    }

}
