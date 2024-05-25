{ pkgs, config, ... }:

let
 githubPublicKey = "
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDn9ze37ERzD4SuAzISViM6xRANUhOMofA32vGwdEfu3jPtUT+JtaR5kHGuufL0o8B6X0qXI61jXponRNm5lAnyw+br7oD1Pw7+05fGMkOVhjiJprK2dod1Wc3KuQ+TLCs4NyIf8E/klR2gYce5JBY7hYD+a6ftQn/pXSu4jF9tdFi7nNmZS1H1L8hW+5sXOhfjP3mXUKPu0BKhXFBhaUqjvHZoJu/ohQpBEuoxMy3BFG1e4WzWIRLeQma6RX/J4S77+8Feca8XoB+rjHphbZbXw5olmLx1MnJSNCQFzUY2y9jtkL/YkEGR3aGzqWmTuZjdS9exM/emEZQzPlcTGWlb randy@randy
";
in
{
  ".ssh/id_github.pub" = {
    text = githubPublicKey;
  };

  ".emacs.d/init.el" = {
    text = builtins.readFile ../shared/config/emacs/init.el;
  };
}
