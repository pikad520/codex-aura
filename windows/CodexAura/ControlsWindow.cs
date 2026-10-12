using System;
using System.Globalization;
using System.Windows;
using System.Windows.Automation;
using System.Windows.Controls;
using System.Windows.Input;

namespace CodexAura;

internal sealed class ControlsWindow : Window
{
    private readonly Slider[] sliders = new Slider[4];
    private readonly TextBox[] fields = new TextBox[4];
    private Appearance appearance;
    private bool syncing;
    internal event Action<Appearance>? Changed;
    internal event Action? ReplayRequested;

    internal ControlsWindow(Appearance initial)
    {
        appearance = initial;
        Title = "Codex Aura · Appearance"; Width = 420; SizeToContent = SizeToContent.Height;
        ResizeMode = ResizeMode.NoResize; Topmost = true; ShowInTaskbar = false;
        WindowStartupLocation = WindowStartupLocation.CenterScreen;
        var root = new StackPanel { Margin = new Thickness(24) };
        Content = root;
        root.Children.Add(new TextBlock { Text = "Changes apply immediately and save automatically.",
            TextWrapping = TextWrapping.Wrap, Margin = new Thickness(0, 0, 0, 20) });
        string[] names = ["Actual opacity (%)", "Saturation", "Contrast", "Brightness"];
        double[] minimum = [0, 0, .5, .2], maximum = [100, 2, 2, 1.5];
        for (var i = 0; i < 4; i++)
        {
            var index = i;
            var row = new DockPanel();
            var field = new TextBox { Width = 72, TextAlignment = TextAlignment.Right, Padding = new Thickness(5, 3, 5, 3) };
            AutomationProperties.SetName(field, names[i] + " value");
            DockPanel.SetDock(field, Dock.Right); row.Children.Add(field);
            row.Children.Add(new Label { Content = names[i], Target = field });
            root.Children.Add(row);
            var slider = new Slider { Minimum = minimum[i], Maximum = maximum[i], TickFrequency = i == 0 ? 1 : .01,
                IsSnapToTickEnabled = true, Margin = new Thickness(0, 8, 0, 16) };
            AutomationProperties.SetName(slider, names[i]);
            root.Children.Add(slider); sliders[i] = slider; fields[i] = field;
            slider.ValueChanged += (_, _) => { if (!syncing) Commit(index, slider.Value); };
            field.LostKeyboardFocus += (_, _) => CommitText(index);
            field.KeyDown += (_, e) => { if (e.Key == Key.Enter) { CommitText(index); e.Handled = true; } };
        }
        var actions = new StackPanel { Orientation = Orientation.Horizontal };
        var reset = new Button { Content = "Restore defaults", Padding = new Thickness(12, 6, 12, 6), Margin = new Thickness(0, 4, 12, 0) };
        var replay = new Button { Content = "Replay intro", Padding = new Thickness(12, 6, 12, 6), Margin = new Thickness(0, 4, 0, 0) };
        reset.Click += (_, _) => { appearance = new(); Sync(); Changed?.Invoke(appearance); };
        replay.Click += (_, _) => ReplayRequested?.Invoke();
        actions.Children.Add(reset); actions.Children.Add(replay); root.Children.Add(actions);
        Sync();
    }
    private void CommitText(int index)
    {
        if (double.TryParse(fields[index].Text, NumberStyles.Float, CultureInfo.CurrentCulture, out var value) && double.IsFinite(value))
            Commit(index, value);
        else Sync();
    }
    private void Commit(int index, double value)
    {
        value = Math.Round(value, index == 0 ? 0 : 2);
        appearance = (index switch
        {
            0 => appearance with { Opacity = value / 100 },
            1 => appearance with { Saturation = value },
            2 => appearance with { Contrast = value },
            _ => appearance with { Brightness = value }
        }).Normalize();
        Sync(); Changed?.Invoke(appearance);
    }
    private void Sync()
    {
        syncing = true;
        double[] values = [appearance.Opacity * 100, appearance.Saturation, appearance.Contrast, appearance.Brightness];
        for (var i = 0; i < 4; i++)
        {
            sliders[i].Value = values[i];
            fields[i].Text = values[i].ToString(i == 0 ? "F0" : "F2", CultureInfo.CurrentCulture);
        }
        syncing = false;
    }
}
