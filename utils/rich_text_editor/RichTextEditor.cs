using Godot;
using System;
using System.Collections.Generic;

public partial class RichTextEditor : Control
{
}

public enum Style
{
    ITALIC,
    BOLD,
    UNDERLINE,
    STRIKETHROUGH
}

public class RichText
{
    List<Segment> segments = new List<Segment>();

    public void InsertTextWithStyle(string text, List<Style> styles, int index)
    {
        List<Segment> newSegments = new List<Segment>();
        int total = 0;
        Boolean inserted = false;
        foreach (Segment seg in segments)
        {
            if (!inserted && index <= total + seg.text.Length)
            {
                int localIndex = index - total;
                newSegments.Add //TODO
            }
        }
    }
}

public class Segment
{
    public List<Style> styles = new List<Style>();
    public string text = "";

    public Segment(string text, List<Style> styles)
    {
        this.text = text;
        this.styles = styles;
    }

    public void ToggleStyle(Style newStyle)
    {
        if (styles.Contains(newStyle))
        {
            styles.Add(newStyle);
        }
    }
}