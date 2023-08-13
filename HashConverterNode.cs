using System;
using System.Collections.Generic;
using Godot;
using Godot.Collections;

public partial class HashConverterNode : Node {
    public string test = "BOB";

    public void PrintNodeName(Node node)
    {
        GD.Print(node.Name);
    }

    public void PrintArray(string[] arr)
    {
        foreach (string element in arr)
        {
            GD.Print(element);
        }
    }

    public void PrintNTimes(string msg, int n)
    {
        for (int i = 0; i < n; ++i)
        {
            GD.Print(msg);
        }
    }
}