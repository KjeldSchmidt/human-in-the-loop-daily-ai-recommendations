from django import forms

from news.models import Feed, FollowUpAnswer


class CustomFeedForm(forms.Form):
    title = forms.CharField(max_length=200, label="Feed name")
    url = forms.URLField(label="RSS URL")
    site_url = forms.URLField(required=False, label="Site URL (optional)")
    category = forms.CharField(max_length=80, required=False, initial="Custom")
    description = forms.CharField(
        required=False,
        widget=forms.Textarea(attrs={"rows": 2}),
    )

    def clean_url(self):
        url = self.cleaned_data["url"].strip()
        if Feed.objects.filter(url=url).exists():
            raise forms.ValidationError("That feed URL is already in the catalog.")
        return url


class FollowUpAnswerForm(forms.ModelForm):
    class Meta:
        model = FollowUpAnswer
        fields = ("answer",)
        widgets = {
            "answer": forms.Textarea(
                attrs={"rows": 3, "placeholder": "A sentence or two is enough…"}
            ),
        }
