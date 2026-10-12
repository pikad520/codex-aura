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
    private readonly ComboBox characterPicker = new();
    private readonly ComboBox languagePicker = new();
    private readonly TextBlock note = new();
    private readonly Label characterLabel = new(), languageLabel = new();
    private readonly Label[] labels = new Label[4];
    private readonly Button reset = new(), replay = new();
    private static readonly string[] Names = ["opacity", "saturation", "contrast", "brightness"];
    private Localization L => new(appearance.Language);
    private Appearance appearance;
    private bool syncing;
    internal event Action<Appearance>? Changed;
    internal event Action? ReplayRequested;

    internal ControlsWindow(Appearance initial)
    {
        appearance = initial;
        Title = L["panelTitle"]; Width = 460; SizeToContent = SizeToContent.Height;
        ResizeMode = ResizeMode.NoResize; Topmost = true; ShowInTaskbar = false;
        WindowStartupLocation = WindowStartupLocation.CenterScreen;
        var root = new StackPanel { Margin = new Thickness(24) };
        Content = root;
        note.TextWrapping = TextWrapping.Wrap; note.Margin = new Thickness(0, 0, 0, 20);
        root.Children.Add(note);
        languageLabel.Target = languagePicker; root.Children.Add(languageLabel);
        foreach (var name in new[] { L["system"], "English", "简体中文", "日本語" }) languagePicker.Items.Add(name);
        languagePicker.Margin = new Thickness(0, 0, 0, 16);
        languagePicker.SelectionChanged += (_, _) => {
            if (syncing) return;
            appearance = appearance with { Language = Localization.Choices[languagePicker.SelectedIndex] };
            ApplyLanguage(); Sync(); Changed?.Invoke(appearance);
        };
        root.Children.Add(languagePicker);
        characterLabel.Target = characterPicker; root.Children.Add(characterLabel);
        characterPicker.Items.Add(L["golden"]); characterPicker.Items.Add(L["blue"]);
        characterPicker.Margin = new Thickness(0, 0, 0, 16);
        AutomationProperties.SetName(characterPicker, L["character"]);
        characterPicker.SelectionChanged += (_, _) => {
            if (syncing) return;
            appearance = appearance with { Character = characterPicker.SelectedIndex == 1 ? "blue-hime" : "golden" };
            Changed?.Invoke(appearance);
        };
        root.Children.Add(characterPicker);
        double[] minimum = [0, 0, .5, .2], maximum = [100, 2, 2, 1.5];
        for (var i = 0; i < 4; i++)
        {
            var index = i;
            var row = new DockPanel();
            var field = new TextBox { Width = 72, TextAlignment = TextAlignment.Right, Padding = new Thickness(5, 3, 5, 3) };
            AutomationProperties.SetName(field, L[Names[i]] + " · " + L["value"]);
            DockPanel.SetDock(field, Dock.Right); row.Children.Add(field);
            labels[i] = new Label { Target = field }; row.Children.Add(labels[i]);
            root.Children.Add(row);
            var slider = new Slider { Minimum = minimum[i], Maximum = maximum[i], TickFrequency = i == 0 ? 1 : .01,
                IsSnapToTickEnabled = true, Margin = new Thickness(0, 8, 0, 16) };
            AutomationProperties.SetName(slider, L[Names[i]]);
            root.Children.Add(slider); sliders[i] = slider; fields[i] = field;
            slider.ValueChanged += (_, _) => { if (!syncing) Commit(index, slider.Value); };
            field.LostKeyboardFocus += (_, _) => CommitText(index);
            field.KeyDown += (_, e) => { if (e.Key == Key.Enter) { CommitText(index); e.Handled = true; } };
        }
        var actions = new StackPanel { Orientation = Orientation.Horizontal };
        reset.Padding = new Thickness(12, 6, 12, 6); reset.Margin = new Thickness(0, 4, 12, 0);
        replay.Padding = new Thickness(12, 6, 12, 6); replay.Margin = new Thickness(0, 4, 0, 0);
        reset.Click += (_, _) => { appearance = new Appearance(Character: appearance.Character, Language: appearance.Language); Sync(); Changed?.Invoke(appearance); };
        replay.Click += (_, _) => ReplayRequested?.Invoke();
        actions.Children.Add(reset); actions.Children.Add(replay); root.Children.Add(actions);
        ApplyLanguage(); Sync();
    }
    private void ApplyLanguage()
    {
        syncing = true;
        Title = L["panelTitle"]; note.Text = L["note"];
        languageLabel.Content = L["language"]; characterLabel.Content = L["character"];
        languagePicker.Items[0] = L["system"];
        characterPicker.Items[0] = L["golden"]; characterPicker.Items[1] = L["blue"];
        AutomationProperties.SetName(languagePicker, L["language"]);
        AutomationProperties.SetName(characterPicker, L["character"]);
        for (var i = 0; i < 4; i++) {
            labels[i].Content = L[Names[i]] + (i == 0 ? " (%)" : " (×)");
            AutomationProperties.SetName(fields[i], L[Names[i]] + " · " + L["value"]);
            AutomationProperties.SetName(sliders[i], L[Names[i]]);
        }
        reset.Content = L["reset"]; replay.Content = L["replay"];
        syncing = false;
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
        languagePicker.SelectedIndex = Array.IndexOf(Localization.Choices, appearance.Language);
        characterPicker.SelectedIndex = appearance.Character == "blue-hime" ? 1 : 0;
        double[] values = [appearance.Opacity * 100, appearance.Saturation, appearance.Contrast, appearance.Brightness];
        for (var i = 0; i < 4; i++)
        {
            sliders[i].Value = values[i];
            fields[i].Text = values[i].ToString(i == 0 ? "F0" : "F2", CultureInfo.CurrentCulture);
        }
        syncing = false;
    }
}
